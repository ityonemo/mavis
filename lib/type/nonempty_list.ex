defmodule Type.NonemptyList do
  @moduledoc """
  Represents nonempty lists.  The empty list is represented by the literal
  `[]`.

  Lists that are optionally nonempty are unions of the empty list and
  the list:

  ```elixir
  iex> list()
  %Type.Union{of: [%Type.NonemptyList{}, []]}
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
  %Type.Union{of: [%Type.NonemptyList{type: %Type{name: :pos_integer}}, []]}
  iex> list(...)
  %Type.NonemptyList{type: %Type{name: :any}}
  iex> list(pos_integer(), ...)
  %Type.NonemptyList{type: %Type{name: :pos_integer}}
  ```

  ### Examples:

  - A the general nonempty list
    ```
    iex> inspect %Type.NonemptyList{}
    "list(...)"
    ```
  - a nonempty list of a given type
    ```elixir
    iex> inspect %Type.NonemptyList{type: %Type{name: :integer}}
    "list(integer(), ...)"
    ```
  - the general list is a union of nonempty list with empty list
    ```elixir
    iex> inspect %Type.Union{of: [%Type.NonemptyList{}, []]}
    "list()"
    ```
  - a general list of a given type
    ```elixir
    iex> inspect %Type.Union{of: [%Type.NonemptyList{type: %Type{name: :integer}}, []]}
    "list(integer())"
    ```
  - an improper list must be nonempty, and looks like the following:
    ```elixir
    iex> inspect %Type.NonemptyList{type: %Type{module: String, name: :t},
    ...>                            final: %Type{module: String, name: :t}}
    "nonempty_improper_list(String.t(), String.t())"
    ```
  - a nonempty maybe improper list should have empty list as a subtype of the final field.
    ```elixir
    iex> inspect %Type.NonemptyList{type: %Type{module: String, name: :t},
    ...>                    final: %Type.Union{of: [[], %Type{module: String, name: :t}]}}
    "nonempty_maybe_improper_list(String.t(), String.t())"
    ```
  - a maybe improper list should have empty list as a subtype of the final field. AND be
    a union with the empty list singleton.
    ```elixir
    iex> inspect %Type.Union{of: [
    ...>                      %Type.NonemptyList{
    ...>                        type: %Type{module: String, name: :t},
    ...>                        final: %Type.Union{of: [%Type{module: String, name: :t}, []]}},
    ...>                        []]}
    "nonempty_maybe_improper_list(String.t(), String.t())"
    ```

  ### Key functions:

  #### comparison

  literal lists are ordered by erlang term order; and precede all abstract
  list types.  Abstract list types are ordered by the type order of their
  content types, followed by the type order of their finals.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.compare(list(...), [])
  :gt
  iex> Type.compare(list(), [])
  :gt
  iex> Type.compare(list(integer()), list(atom()))
  :lt
  iex> Type.compare(%Type.NonemptyList{final: integer()}, %Type.NonemptyList{final: atom()})
  :lt
  ```

  #### intersection

  The intersection of two list types is the intersection of their contents.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersection(list(...), list())
  %Type.NonemptyList{}
  iex> Type.intersection(list(1..20), list(10..30))
  %Type.NonemptyList{type: 10..20}
  ```

  #### union

  The union of two list types is the union of their contents.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.union(list(...), list())
  %Type.NonemptyList{}
  iex> Type.union(list(1..10), list(10..20))
  %Type.NonemptyList{type: 1..20}
  ```

  #### subtype?

  A list type is a subtype of another if its contents are subtypes of each other.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.subtype?(list(...), list())
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
  {:maybe, [%Type.Message{type: %Type.Union{of: [%Type.NonemptyList{type: 1..10}, []]},
                          target: %Type.Union{of: [%Type.NonemptyList{type: %Type{name: :atom}}, []]}}]}
  iex> Type.usable_as(list(), list(...))
  {:maybe, [%Type.Message{type: %Type.Union{of: [%Type.NonemptyList{}, []]}, target: %Type.NonemptyList{}}]}
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

  def usable_literal(list, literal, so_far \\ :ok)
  def usable_literal(list, [head | rest], so_far) do
    next_result = head
    |> Type.usable_as(list.type)
    |> Type.ternary_and(so_far)

    usable_literal(list, rest, next_result)
  end
  def usable_literal(list, final, so_far) do
    final
    |> Type.usable_as(list.final)
    |> Type.ternary_and(so_far)
  end

  defimpl Type.Properties do
    import Type, only: :macros

    use Type.Helpers

    alias Type.{NonemptyList, Message, Union}

    group_compare do
      def group_compare(_, lst) when is_list(lst), do: :gt
      def group_compare(a, b) do
        case Type.compare(a.type, b.type) do
          :eq -> Type.compare(a.final, b.final)
          ordered -> ordered
        end
      end
    end

    usable_as do
      def usable_as(challenge, iolist(), meta) do
        Type.Iolist.usable_as_iolist(challenge, meta)
      end

      def usable_as(challenge, target = %NonemptyList{}, meta) do
        case Type.usable_as(challenge.type, target.type, meta) do
          {:error, _} -> {:maybe, [Message.make(challenge.type, target.type, meta)]}
          any -> any
        end
        |> Type.ternary_and(Type.usable_as(challenge.final, target.final, meta))
        |> case do
          :ok -> :ok
          {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
          {:error, _} -> {:error, Message.make(challenge, target, meta)}
        end
      end

      def usable_as(challenge, target, meta) when is_list(target) do
        # TODO: make this work with improper lists
        challenge
        |> NonemptyList.usable_literal(target)
        |> case do
          {:error, _} ->
            {:error, Message.make(challenge, target, meta)}
          {:maybe, _} ->
            {:maybe, [Message.make(challenge, target, meta)]}
          :ok ->
            {:maybe, [Message.make(challenge, target, meta)]}
        end
      end
    end

    intersection do
      def intersection(type, list) when is_list(list) do
        Type.intersection(list, type)
      end
      def intersection(a, b = %NonemptyList{}) do
        case {Type.intersection(a.type, b.type), Type.intersection(a.final, b.final)} do
          {none(), _} -> none()
          {_, none()} -> none()
          {type, final} ->
            %NonemptyList{type: type, final: final}
        end
      end
      def intersection(a, iolist()), do: Type.Iolist.intersection_with(a)
    end

    subtype do
      # can't simply forward to usable_as, because any of the encapsulated
      # types might have a usable_as rule that isn't strictly subtype?
      def subtype?(list, iolist()), do: Type.Iolist.subtype_of_iolist?(list)
      def subtype?(challenge, target = %NonemptyList{}) do
        (Type.subtype?(challenge.type, target.type) and
          Type.subtype?(challenge.final, target.final))
      end
      def subtype?(challenge, %Union{of: types}) do
        Enum.any?(types, &Type.subtype?(challenge, &1))
      end
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    import Type, only: :macros

    #########################################################
    ## SPECIAL CASES

    # override for charlist
    def inspect(list = %{final: [], type: 0..1114111}, _) do
      "nonempty_charlist()"
    end
    def inspect(%{final: [], type: any()}, _), do: "list(...)"
    # keyword list literal syntax
    def inspect(%{
        final: [],
        type: tuple({k, v})}, opts) when is_atom(k) do
      concat(["list(", "#{k}: ", to_doc(v, opts), ", ...)"])
    end
    def inspect(list = %{
        final: [],
        type: type = %Type.Union{}}, opts) do
      if Enum.all?(type.of, &match?(
            tuple({e, _}) when is_atom(e), &1)) do
        ["list(",
          type.of
          |> Enum.reverse
          |> Enum.map(fn %{elements: [atom, type]} ->
            ["#{atom}: ", to_doc(type, opts)]
          end)
          |> Enum.intersperse(", "),
          "...)"]
        |> List.flatten
        |> concat
      else
        render_basic(list, opts)
      end
    end
    # keyword syntax
    def inspect(list(tuple({atom(), any()})), _) do
      "keyword(...)"
    end
    def inspect(list(tuple({atom(), type})), opts) do
      concat(["keyword(", to_doc(type, opts), "...)"])
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
      concat(["list(", to_doc(list.type, opts), ", ...)"])
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
