defmodule Type.Literal do
  @enforce_keys [:value]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    value: bitstring | nonempty_list
  }

  @moduledoc """
  Represents literal values, for the following types:
  - binaries and bitstrings
  - floats
  - lists (except empty list)

  Note that tuples and maps can

  There is one field for the struct defined by this value.

  - `value`: the literal value of this type.

  Concretely, the following types are implemented as

  ### Shortcut Form

  The `Type` module lets you specify a literal using "shortcut form" via the
  `Type.literal/1` macro.

  ### Examples

  ```
  iex> import Type, only: :macros
  iex> literal(47.0)
  %Type.Literal{value: 47.0}
  iex> literal("foo")
  %Type.Literal{value: "foo"}
  iex> literal([:bar, :baz])
  %Type.Literal{value: [:bar, :baz]}
  iex> inspect literal(47.0)
  "literal(47.0)"
  ```

  ### Key functions:

  #### comparison

  All literals are arranged in erlang term order, and less than all general
  types in the same class of type.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.compare(literal([:foo, :bar]), literal([:foo, :baz]))
  :lt
  iex> Type.compare(literal([:foo, :bar]), list(%Type.Union{of: [:foo, :bar]}))
  :lt
  iex> Type.compare(literal("foo"), literal("bar"))
  :gt
  iex> Type.compare(literal("foo"), %Type.Bitstring{size: 24})
  :lt
  ```

  #### intersection

  The intersection of a literal with itself or a supertype is itself; and
  generally with others it's `none()`

  ```elixir
  iex> import Type, only: :macros
  iex> Type.intersection(literal("foo"), literal("foo"))
  literal("foo")
  iex> Type.intersection(literal("foo"), literal("bar"))
  none()
  iex> Type.intersection(literal("foo"), binary())
  literal("foo")
  ```

  #### union

  The intersection of two list types is the union of their contents; a
  `nonempty: true` list type intersected with a `nonempty: false` list type is `nonempty: false`

  ```elixir
  iex> import Type, only: :macros
  iex> Type.union(literal("foo"), literal("foo"))
  literal("foo")
  iex> Type.union(literal("foo"), literal("bar"))
  %Type.Union{of: [literal("foo"), literal("bar")]}
  iex> Type.union(literal("foo"), binary())
  binary()
  ```

  #### subtype?

  A list type is a subtype of another if its contents are subtypes of each other;
  a `nonempty: true` list type is subtype of its `nonempty: false` counterpart.

  - List literals are lists with properties as you might expect.
    ```
    iex> import Type, only: :macros
    iex> Type.subtype?(literal([:foo, :bar]), list())
    true
    iex> Type.subtype?(literal([:foo, :bar]), list(atom()))
    true
    iex> Type.subtype?(literal([:foo, :bar]), list(integer()))
    false
    ```
  - Bitstring literals are bitstring with properties as you might expect.
    ```
    iex> import Type, only: :macros
    iex> Type.subtype?(literal("foo"), bitstring())
    true
    iex> Type.subtype?(literal("foo"), binary())
    true
    iex> Type.subtype?(literal("foo"), %Type.Bitstring{unit: 16})
    false
    ```

  #### usable_as

  A literal is usable_as a general type if it is a subtype of the general type

  ```elixir
  iex> import Type, only: :macros
  iex> Type.usable_as(literal("foo"), bitstring())
  :ok
  iex> Type.usable_as(literal("foo"), binary())
  :ok
  iex> Type.usable_as(literal("foo"), %Type.Bitstring{size: 16})
  {:error, %Type.Message{type: %Type.Literal{value: "foo"}, target: %Type.Bitstring{size: 16}}}
  ```
  """

  ## PRIVATE API.  USED AS A CONVENIENCE FUNCTION.
  def _normalize(value) when is_float(value), do: _normalize(value, :float)
  def _normalize(value) when is_bitstring(value), do: _normalize(value, :bitstring)
  def _normalize(value) when is_list(value), do: _normalize(value, :list)

  def _normalize(_, :float) do
    %Type{name: :float}
  end
  def _normalize(value, :bitstring) do
    %Type.Bitstring{size: :erlang.size(value)}
  end
  def _normalize(value, :list) do
    type = value
    |> Enum.map(&Type.normalize/1)
    |> Enum.into(%Type.Union{})

    %Type.List{type: type}
  end

  defimpl Type.Properties do
    import Type, only: :macros
    import Type.Helpers

    alias Type.Literal

    ###########################################################################
    ## COMPARISON
    def compare(this, other) do
      this_group = typegroup(this)
      other_group = Type.typegroup(other)
      cond do
        this_group > other_group -> :gt
        this_group < other_group -> :lt
        true ->
          group_compare(this, other)
      end
    end

    def typegroup(literal), do: group_of(literal.value)

    @float_group 2
    @list_group Type.Properties.typegroup(%Type.List{})
    @bitstring_group Type.Properties.typegroup(%Type.Bitstring{})

    defp group_of(float) when is_float(float), do: @float_group
    defp group_of(list) when is_list(list), do: @list_group
    defp group_of(bitstring) when is_bitstring(bitstring), do: @bitstring_group

    group_compare do
      def group_compare(%{value: rvalue}, %Literal{value: lvalue})
        when rvalue < lvalue, do: :lt
      def group_compare(%{value: rvalue}, %Literal{value: lvalue})
        when rvalue == lvalue, do: :eq
      def group_compare(%{value: rvalue}, %Literal{value: lvalue})
        when rvalue > lvalue, do: :gt
      def group_compare(_, _), do: :lt
    end

    ###########################################################################
    ## SUBTYPE

    subtype :usable_as

    ###########################################################################
    ## USABLE_AS

    alias Type.Message

    usable_as do
      def usable_as(%{value: float}, float(), _meta) when is_float(float), do: :ok
      def usable_as(type = %{value: bitstring}, target = %Type.Bitstring{}, meta)
          when is_bitstring(bitstring) do
        %Type.Bitstring{size: :erlang.bit_size(bitstring)}
        |> Type.usable_as(target, meta)
        |> case do
          {:error, _} -> {:error, Message.make(type, target, meta)}
          {:maybe, _} -> {:maybe, [Message.make(type, target, meta)]}
          :ok -> :ok
        end
      end
      def usable_as(type = %{value: binary}, target = %Type{module: String, name: t}, meta)
          when is_binary(binary) do
        case target.params do
          [] -> :ok
          [v] when :erlang.size(binary) == v -> :ok
          _ -> {:error, Message.make(type, target, meta)}
        end
      end
      def usable_as(type = %{value: value}, target = %Type.List{}, meta) when is_list(value) do
        value
        |> Enum.map(&Type.usable_as(&1, target.type, meta))
        |> Enum.reduce(&Type.ternary_and/2)
        |> case do
          {:error, _} -> {:error, Message.make(type, target, meta)}
          ok -> ok
        end
      end
      def usable_as(lhs, rhs = %Literal{}, meta) do
        {:error, Message.make(lhs, rhs, meta)}
      end
    end

    intersection do
      def intersection(_, %Literal{}), do: none()
      def intersection(literal, type) do
        if subtype?(literal, type) do
          literal
        else
          none()
        end
      end
    end

    def normalize(%{value: value}) do
      Literal._normalize(value)
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{value: value}, opts) do
      concat(["literal(", to_doc(value, opts), ")"])
    end
  end
end
