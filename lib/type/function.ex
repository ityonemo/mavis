defmodule Type.Function.F do
  defmacro singleton(params, return) do
    quote do
      %{branches: [%{params: unquote(params), return: unquote(return)}]}
    end
  end
end

defmodule Type.Function do
  use Type.Helpers
  @moduledoc """
  Represents a function type.

  A function is a list of "function branches".  Function branches represent
  specifications for separate subdomains of a single function.  In order to
  be valid, the domains must be disjoint.  If any input falls outside of all
  domain specifications, then it should be considered to raise an error.

  There is one field for the struct defined by this module:

  - `branches` a list of `t:Type.Function.Branch.t/0` structs that constitute
    the domains of the function.

  ### Shortcut Form

  The `Type` module lets you specify a function using "shortcut form" via the `Type.function/1` macro:

  ```elixir
  iex> import Type, only: :macros
  iex> type((atom() -> pos_integer()))
  %Type.Function{branches: [%Type.Function.Branch{params: [%Type{name: :atom}], return: %Type{name: :pos_integer}}]}
  ```

  ### Validations

  - n-arity and any-arity functions may only have one branch.
  - the branches must have fully disjoint domains.

  ### Key functions:

  #### comparison

  Functions are first ordered by their arity, with higher-arity functions
  ranked greater. Two functions with the same arity are first ranked by the
  backwards order of the unions of their domains, followed by the order of
  their ranges. An n-arity any function is greater than any function of arity
  n, and afunction that takes any domain is greater than any function.  If
  two functions have the same domains and ranges then their relative order
  is not well defined, but they must not be equal unless they are equal.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.compare(type(( -> atom())), type(( -> integer())))
  :gt
  iex> Type.compare(type((_ -> integer())),
  ...>              type((atom() -> integer())))
  :gt
  iex> Type.compare(type((:... -> integer())),
  ...>              type((_ -> integer())))
  :gt
  iex> integer_or_atom = Type.union(integer(), atom())
  iex> Type.compare(type((integer_or_atom -> integer())),
  ...>              type((atom() -> integer())))
  :lt
  iex> Type.compare(type((integer() -> integer()) ||| (atom() -> atom())),
  ...>              type((atom() -> integer())))
  :lt
  iex> Type.compare(type((atom() -> integer_or_atom)),
  ...>              type((atom() -> integer())))
  :gt
  ```

  #### intersection

  Functions with distinct parameter types are nonoverlapping, even if their parameter
  types overlap.  If they have the same parameters, then their return values are intersected.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersect(type(( -> 1..10)), type(( -> integer())))
  %Type.Function{branches: [%Type.Function.Branch{params: [], return: 1..10}]}
  iex> Type.intersect(type((integer() -> integer())),
  ...>                   type((1..10 -> integer())))
  %Type{name: :none}
  ```

  functions with `:any` parameters intersected with a function with specified
  parameters will adopt the parameters of the intersected function.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersect(type((... -> pos_integer())),
  ...>                   type((1..10 -> pos_integer())))
  %Type.Function{branches: [%Type.Function.Branch{params: [1..10], return: %Type{name: :pos_integer}}]}
  ```

  n-arity functions with `:any` parameters intersected with a function with
  the same arity will adopt the parameters of the intersected function.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersect(type((_ -> pos_integer())),
  ...>                   type((1..10 -> pos_integer())))
  %Type.Function{branches: [%Type.Function.Branch{params: [1..10], return: %Type{name: :pos_integer}}]}

  iex> Type.intersect(type((_ -> pos_integer())),
  ...>                   type((integer(), integer() -> pos_integer())))
  %Type{name: :none}
  ```

  #### union

  Functions are generally not merged in union operations, but if their parameters are
  identical then their return types will be merged.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.union(type(( -> 1..10)), type(( -> 11..20)))
  %Type.Function{branches: [%Type.Function.Branch{params: [], return: 1..20}]}
  ```

  #### subtype?

  A function type is the subtype of another if it has the same parameters and its return
  value type is the subtype of the other's

  ```elixir
  iex> import Type, only: :macros
  iex> Type.subtype?(type((integer() -> 1..10)),
  ...>               type((integer() -> integer())))
  true
  ```

  #### usable_as

  The `usable_as` relationship for functions may not necessarily be obvious.  An
  easy way to think about it, is:  if I passed a function with this type to a
  function that demanded the other type how confident would I be that it would
  not crash.

  A function is `usable_as` another function if all of its parameters are
  supertypes of the targeted function; and if its return type is subtypes of the
  return type of the targeted function.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.usable_as(type((pos_integer() -> 1..10)), type((1..10 -> pos_integer())))
  :ok
  iex> Type.usable_as(type((1..10 -> 1..10)), type((pos_integer() -> pos_integer())))
  {:maybe, [%Type.Message{challenge: %Type.Function{branches: [%Type.Function.Branch{params: [1..10], return: 1..10}]},
                          target: %Type.Function{branches: [%Type.Function.Branch{params: [%Type{name: :pos_integer}], return: %Type{name: :pos_integer}}]}}]}
  iex> Type.usable_as(type(( -> atom())), type(( -> pos_integer())))
  {:error, %Type.Message{challenge: %Type.Function{branches: [%Type.Function.Branch{params: [], return: %Type{name: :atom}}]},
                         target: %Type.Function{branches: [%Type.Function.Branch{params: [], return: %Type{name: :pos_integer}}]}}}
  ```
  """

  @enforce_keys [:branches]
  defstruct @enforce_keys

  alias Type.Function.F
  alias Type.Function.Branch
  alias Type.Message

  require F

  @type t :: %__MODULE__{
    branches: [Branch.t, ...]
  }

  @any %Type{module: nil, name: :any, params: []}
  @none %Type{module: nil, name: :none, params: []}
  @anyfun %{__struct__: __MODULE__, branches: [%Branch{params: :any, return: @any}]}

  def merge(@anyfun, _), do: {:merge, [@anyfun]}
  def merge(_, @anyfun), do: {:merge, [@anyfun]}
  def merge(_, _) do
    :nomerge
  end

  def intersect(%{branches: [lbranch]}, %__MODULE__{branches: [rbranch]}) do
    case Type.intersect(lbranch, rbranch) do
      @none ->
        @none
      intersection ->
        %__MODULE__{branches: [intersection]}
    end
  end
  def intersect(_, _), do: @none

  def compare(F.singleton(:any, r1), F.singleton(:any, r2)) do
    Type.compare(r1, r2)
  end

  def compare(F.singleton(:any, _), _), do: :gt
  def compare(_, F.singleton(:any, _)), do: :lt

  def compare(F.singleton(n1, _), F.singleton(n2, _))
    when is_integer(n1) and is_integer(n2) and n1 > n2, do: :gt

  def compare(F.singleton(n1, _), F.singleton(n2, _))
    when is_integer(n1) and is_integer(n2) and n1 < n2, do: :lt

  def compare(F.singleton(n1, r1), F.singleton(n2, r2))
    when is_integer(n1) and is_integer(n2), do: Type.compare(r1, r2)

  def compare(F.singleton(n, _), %{branches: [%{params: list} | _]})
      when is_integer(n) and is_list(list) do
    if n >= length(list), do: :gt, else: :lt
  end

  def compare(%{branches: [%{params: list} | _]}, F.singleton(n, _))
      when is_integer(n) and is_list(list) do
    if n >= length(list), do: :lt, else: :gt
  end

  def compare(f1 = %{branches: [%{params: p1} | _]}, f2 = %{branches: [%{params: p2} | _]}) do
    l1 = length(p1)
    l2 = length(p2)
    # NB: u2 and u1 are reversed in the second arm of the with statement
    with true <- l1 == l2,
         u1 = branch_union(f1.branches),
         u2 = branch_union(f2.branches),
         :eq <- Type.compare(u2.params, u1.params),
         :eq <- Type.compare(u1.return, u2.return) do
      # equal case should be handled at the top level.
      if f1 < f2, do: :lt, else: :gt
    else
      false when l1 > l2 -> :gt
      false -> :lt
      order -> order
    end
  end

  @spec branch_union([Type.Function.Branch.t]) :: Type.t
  defp branch_union(branches) do
    Enum.reduce(branches, fn
      r = %{params: p1, return: r1}, %{params: p2, return: r2} ->
        new_params = p1
        |> Enum.zip(p2)
        |> Enum.map(fn {pp1, pp2} -> Type.union(pp1, pp2) end)

        %{r | params: new_params, return: Type.union(r1, r2)}
    end)
  end

  @any %Type{name: :any, module: nil, params: []}
  def usable_as(_challenge, @any , _meta), do: :ok
  def usable_as(challenge, target = %__MODULE__{}, meta) do
    case Enum.reduce(target.branches, :ok, fn branch, so_far ->
      branch
      |> Branch.covered_by(challenge.branches)
      |> Type.ternary_and(so_far)
    end) do
      :ok -> :ok
      {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
      {:error, _} -> {:error, Message.make(challenge, target, meta)}
    end
  end
  def usable_as(challenge, target, meta), do: {:error, Message.make(challenge, target, meta)}

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{branches: [branch]}, opts) do
      to_doc(branch, opts)
    end

    def inspect(%{branches: branches}, opts) do
      custom_options = Keyword.put(opts.custom_options, :no_type, true)

      branches = branches
      |> Enum.map(&to_doc(&1, %{opts | custom_options: custom_options}))
      |> Enum.intersperse(" ||| ")

      concat(["type("] ++ branches ++ [")"])
    end
  end
end
