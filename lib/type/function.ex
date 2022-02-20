defmodule Type.Function do
  use Type.Helpers, default_subtype: true
  @moduledoc """
  Represents a function type.

  There are two fields for the struct defined by this module.

  - `params` a list of types for the function arguments.  Note that the arity
    of the function is the length of this list.  May also be the atom `:any`
    which corresponds to "a function of any arity".
  - `return` the type of the returned value.

  ### Examples:

  - `(... -> integer())` would be represented as `%Type.Function{params: :any, return: %Type{name: :integer}}`
  - `(integer() -> integer())` would be represented as `%Type.Function{params: [%Type{name: :integer}], return: %Type{name: :integer}}`

  ### Shortcut Form

  The `Type` module lets you specify a function using "shortcut form" via the `Type.function/1` macro:

  ```
  iex> import Type, only: :macros
  iex> type((atom() -> pos_integer()))
  %Type.Function{branches: [%Type.Function.Branch{params: [%Type{name: :atom}], return: %Type{name: :pos_integer}}]}
  ```

  ### Inference

  By default, Mavis will not attempt to perform inference on function types.

  ```elixir
  iex> inspect Type.of(&(&1 + 1))
  "(any() -> any())"
  ```

  If you would like to perform inference on the function to obtain
  more details on the acceptable function types, set the inference
  environment variable.  For example, if you're using the `:mavis_inference` hex package, do:

  ```
  Application.put_env(:mavis, :inference, Type.Inference)
  ```

  The default module for this is `Type.NoInference`

  ### Key functions:

  #### comparison

  Functions are ordered first by the type order on their return type,
  followed by type order on their parameters.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.compare(type(( -> atom())), type(( -> integer())))
  :gt
  iex> Type.compare(type((integer() -> integer())),
  ...>              type((atom() -> integer())))
  :lt
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

  functions with `:any` parameters intersected with a function with specified parameters
  will adopt the parameters of the intersected function.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersect(type((... -> pos_integer())),
  ...>                   type((1..10 -> pos_integer())))
  %Type.Function{branches: [%Type.Function.Branch{params: [1..10], return: %Type{name: :pos_integer}}]}
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

  alias Type.Function.Branch
  alias Type.Message

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

  def compare(%{branches: [branch | lrest]}, %__MODULE__{branches: [branch | rrest]}) do
    compare(%__MODULE__{branches: lrest}, %__MODULE__{branches: rrest})
  end

  def compare(%{branches: [lbranch | _]}, %__MODULE__{branches: [rbranch | _]}) do
    Type.compare(lbranch, rbranch)
  end

  # NOTE: these two function heads should only be accessible internally as
  # a function with empty list branches is not supported.
  def compare(%{branches: []}, %__MODULE__{branches: [_branch | _]}), do: :gt
  def compare(%{branches: [_branch | _]}, %__MODULE__{branches: []}), do: :lt

  def usable_as(challenge, target, meta) do
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
