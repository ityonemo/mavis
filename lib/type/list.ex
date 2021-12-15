defmodule Type.List do
  @moduledoc """
  Represents nonempty lists.  The empty list is represented by the literal
  `[]`.

  Lists that are optionally nonempty are unions of the empty list and
  the list:

  ```elixir
  iex> list()
  %Type.Union{of: [%Type.List{}, []]}
  ```
  The documentation for this module will encompass usage of both
  nonempty and maybe-nonempty lists.

  There are two fields for the struct defined by this module.

  - `type` the type for all elements of the list, except the final element
  - `final` the type of the final element.  Typically this is `[]`, but other
    types may be used as the final element and these are called `improper` lists.

  ### Shortcut Form

  The `Type` module lets you specify a list using "shortcut form" via the
  `Type.list/1` and `Type.list/2` macros:

  ```elixir
  iex> import Type, only: :macros
  iex> list(pos_integer())
  %Type.Union{of: [%Type.List{type: %Type{name: :pos_integer}}, []]}
  iex> type([...])
  %Type.List{type: %Type{name: :any}}
  iex> nonempty_list(pos_integer())
  %Type.List{type: %Type{name: :pos_integer}}
  ```

  ### Examples:

  - A the general nonempty list
    ```
    iex> inspect %Type.List{}
    "type([...])"
    ```
  - a nonempty list of a given type
    ```elixir
    iex> inspect %Type.List{type: %Type{name: :integer}}
    "list(integer(), ...)"
    ```
  - the general list is a union of nonempty list with empty list
    ```elixir
    iex> inspect %Type.Union{of: [%Type.List{}, []]}
    "list()"
    ```
  - a general list of a given type
    ```elixir
    iex> inspect %Type.Union{of: [%Type.List{type: %Type{name: :integer}}, []]}
    "list(integer())"
    ```
  - an improper list must be nonempty, and looks like the following:
    ```elixir
    iex> inspect %Type.List{type: %Type{module: String, name: :t},
    ...>                            final: %Type{module: String, name: :t}}
    "nonempty_improper_list(String.t(), String.t())"
    ```
  - a nonempty maybe improper list should have empty list as a subtype of the final field.
    ```elixir
    iex> inspect %Type.List{type: %Type{module: String, name: :t},
    ...>                    final: %Type.Union{of: [[], %Type{module: String, name: :t}]}}
    "nonempty_maybe_improper_list(String.t(), String.t())"
    ```
  - a maybe improper list should have empty list as a subtype of the final field. AND be
    a union with the empty list singleton.
    ```elixir
    iex> inspect %Type.Union{of: [
    ...>                      %Type.List{
    ...>                        type: %Type{module: String, name: :t},
    ...>                        final: %Type.Union{of: [%Type{module: String, name: :t}, []]}},
    ...>                        []]}
    "maybe_improper_list(String.t(), String.t())"
    ```

  ### Key functions:

  #### comparison

  literal lists are ordered by erlang term order; and precede all abstract
  list types.  Abstract list types are ordered by the type order of their
  content types, followed by the type order of their finals.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.compare(type([...]), [])
  :gt
  iex> Type.compare(list(), [])
  :gt
  iex> Type.compare(list(integer()), list(atom()))
  :lt
  iex> Type.compare(%Type.List{final: integer()}, %Type.List{final: atom()})
  :lt
  ```

  #### intersection

  The intersection of two list types is the intersection of their contents.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersect(type([...]), list())
  %Type.List{}
  iex> Type.intersect(nonempty_list(1..20), nonempty_list(10..30))
  %Type.List{type: 10..20}
  iex> inspect Type.intersect(list(1..20), list(10..30))
  "list(10..20)"
  ```

  #### union

  The union of two list types is the union of their contents.  Note
  that that even partially disjoint unions cannot be merged (see the
  last example).

  ```elixir
  iex> import Type, only: :macros
  iex> Type.union(type([...]), list())
  %Type.Union{of: [%Type.List{}, []]}
  iex> inspect Type.union(list(1..10), list(10..20))
  "list(10..20) | list(1..10)"
  ```

  #### subtype?

  A list type is a subtype of another if its contents are subtypes of each other.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.subtype?(type([...]), list())
  true
  iex> Type.subtype?(list(1..10), list(2..30))
  false
  ```

  #### usable_as

  A list type is `usable_as` another if its contents are `usable_as` the other's.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.usable_as(list(1..10), list(integer()))
  :ok
  iex> Type.usable_as(list(1..10), list(atom())) # note it might be the empty list
  {:maybe, [%Type.Message{type: %Type.Union{of: [%Type.List{type: 1..10}, []]},
                          target: %Type.Union{of: [%Type.List{type: %Type{name: :atom}}, []]}}]}
  iex> Type.usable_as(list(), type([...]))
  {:maybe, [%Type.Message{type: %Type.Union{of: [%Type.List{}, []]}, target: %Type.List{}}]}
  ```

  """

  defstruct [
    type: %Type{name: :any},
    final: []
  ]

  @type t :: %__MODULE__{
    type: Type.t,
    final: Type.t
  }

  use Type.Helpers
  alias Type.Message

  @none %Type{name: :none}
  @binary %Type.Bitstring{unit: 8}
  @byte 0..255
  @iotype %Type.Union{of: [@binary, %Type{name: :iolist}, @byte]}
  @iofinal %Type.Union{of: [@binary, []]}

  def compare(_, lst) when is_list(lst), do: :gt
  def compare(l, %Type{module: nil, name: :iolist, params: []}) do
    case Type.compare(l.type, @iotype) do
      :eq -> Type.compare(l.final, @iofinal)
      ordered -> ordered
    end
  end
  def compare(a, b) do
    case Type.compare(a.type, b.type) do
      :eq -> Type.compare(a.final, b.final)
      ordered -> ordered
    end
  end

  def merge(%{type: type, final: lfinal}, %Type.List{type: type, final: rfinal}) do
    {:merge, [%Type.List{type: type, final: Type.union(lfinal, rfinal)}]}
  end
  def merge(%{type: ltype, final: final}, %Type.List{type: rtype, final: final}) do
    {:merge, [%Type.List{type: Type.union(ltype, rtype), final: final}]}
  end
  def merge(%{type: _type, final: _final}, []), do: :nomerge
  def merge(%{type: type, final: final}, list) when is_list(list) do
    merge_list(type, final, list)
  end
  def merge(_, _), do: :nomerge

  defp merge_list(type, final, [head | tail]) do
    if Type.subtype?(head, type) do
      merge_list(type, final, tail)
    else
      :nomerge
    end
  end
  defp merge_list(type, final, last) do
    if Type.subtype?(last, final) do
      {:merge, [%Type.List{type: type, final: final}]}
    else
      :nomerge
    end
  end

  def intersect(_, []), do: @none
  def intersect(type, list) when is_list(list) do
    intersect_list(type, list, [])
  end
  def intersect(a, b = %Type.List{}) do
    case {Type.intersect(a.type, b.type), Type.intersect(a.final, b.final)} do
      {@none, _} -> @none
      {_, @none} -> @none
      {type, final} ->
        %Type.List{type: type, final: final}
    end
  end
  def intersect(l, %Type{module: nil, name: :iolist, params: []}) do
    case {Type.intersect(l.type, @iotype), Type.intersect(l.final, @iofinal)} do
      {@none, _} -> @none
      {_, @none} -> @none
      {type, final} ->
        %Type.List{type: type, final: final}
    end
  end
  def intersect(_, _), do: @none

  defp intersect_list(type, [head | rest], so_far) do
    case Type.intersect(type.type, head) do
      @none -> @none
      intersection -> intersect_list(type, rest, [intersection | so_far])
    end
  end
  defp intersect_list(type, final, so_far) do
    case Type.intersect(type.final, final) do
      @none -> @none
      intersection -> reverse_prepend(so_far, intersection)
    end
  end

  defp reverse_prepend([head | rest], so_far), do: reverse_prepend(rest, [head | so_far])
  defp reverse_prepend([], so_far), do: so_far

  def usable_as(target, list, meta) when is_list(list) do
    case usable_as_list(target, list) do
      :maybe -> {:maybe, [Message.make(target, list, meta)]}
      :error -> {:error, Message.make(target, list, meta)}
    end
  end
  def usable_as(
      target = %{type: ltype, final: lfinal},
      challenge = %Type.List{type: rtype, final: rfinal},
      meta) do

    typecomp = Type.usable_as(ltype, rtype, [])
    finalcomp = Type.usable_as(lfinal, rfinal, [])

    case Type.ternary_and(typecomp, finalcomp) do
      :ok -> :ok
      {:maybe, _} -> {:maybe, [Message.make(target, challenge, meta)]}
      {:error, _} -> {:error, Message.make(target, challenge, meta)}
    end
  end
  def usable_as(target, challenge, meta) do
    {:error, Message.make(target, challenge, meta)}
  end

  defp usable_as_list(target = %{type: type}, [head | rest]) do
    case Type.usable_as(type, head, []) do
      :ok -> usable_as_list(target, rest)
      {:maybe, _} -> usable_as_list(target, rest)
      {:error, _} -> :error
    end
  end
  defp usable_as_list(%{final: final}, final_element) do
    case Type.usable_as(final, final_element, []) do
      :ok -> :maybe
      {:maybe, _} -> :maybe
      {:error, _} -> :error
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    import Type, only: :macros

    #########################################################
    ## SPECIAL CASES

    # override for charlist
    def inspect(list = %{final: [], type: 0..0x10_FFFF}, _) do
      "nonempty_charlist()"
    end
    def inspect(%{final: [], type: any()}, _), do: "type([...])"
    # keyword list literal syntax
    def inspect(%{
        final: [],
        type: type({k, v})}, opts) when is_atom(k) do
      concat(["type([", "#{k}: ", to_doc(v, opts), ", ...])"])
    end
    def inspect(list = %{
        final: [],
        type: type = %Type.Union{}}, opts) do
      if Enum.all?(type.of, &match?(
            type({e, _}) when is_atom(e), &1)) do
        ["type([",
          type.of
          |> Enum.reverse
          |> Enum.map(fn %{elements: [atom, type]} ->
            ["#{atom}: ", to_doc(type, opts)]
          end)
          |> Enum.intersperse(", "),
          "...])"]
        |> List.flatten
        |> concat
      else
        render_basic(list, opts)
      end
    end
    # keyword syntax
    def inspect(keyword(), _) do
      "keyword()"
    end
    def inspect(keyword(t), opts) do
      concat(["keyword(", to_doc(t, opts), ")"])
    end

    ##########################################################
    ## GENERAL CASES

    def inspect(list = %{final: []}, opts), do: render_basic(list, opts)
    # check for maybe_improper
    def inspect(list = %{final: final = %Type.Union{}}, opts) do
      if [] in final.of do
        render_maybe_improper(list, opts)
      else
        render_improper(list, opts)
      end
    end
    def inspect(list = %{type: any(), final: any()}, _) do
      "nonempty_maybe_improper_list()"
    end
    def inspect(list, opts), do: render_improper(list, opts)

    defp render_basic(list, opts) do
      concat(["type([", to_doc(list.type, opts), ", ...])"])
    end

    defp render_maybe_improper(list, opts) do
      improper_final = Enum.into(list.final.of -- [[]], %Type.Union{})
      concat(["nonempty_maybe_improper_list(",
              to_doc(list.type, opts), ", ",
              to_doc(improper_final, opts), ")"])
    end

    defp render_improper(list, opts) do
      concat(["nonempty_improper_list(",
              to_doc(list.type, opts), ", ",
              to_doc(list.final, opts), ")"])
    end
  end
end
