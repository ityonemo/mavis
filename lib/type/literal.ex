defmodule Type.Literal do
  @enforce_keys [:value]
  defstruct @enforce_keys

  @moduledoc """
  Represents literal values, except for the following literals:
  - Empty List, which is `[]`
  - integers, which are themselves
  - atoms, which are themselves
  - tuples, which can be decomposed into singletons
  - maps, which can be decomposed into singletons

  There is one field for the struct defined by this value.

  - `value`: the literal value of this type.

  Concretely, the following types are implemented as

  ### Shortcut Form

  The `Type` module lets you specify a literal using "shortcut form" via the
  `Type.literal/1` macro.

  ### Examples

  ```
  iex> import Type, only: :macros
  iex> literal(%{foo: :bar})
  %Type.Literal{value: %{foo: :bar}}
  iex> literal("foo")
  %Type.Literal{value: "foo"}
  iex> literal([])
  []
  iex> literal(:foo)
  :foo
  iex> literal(%{foo: "bar"})
  %Type.Map{required: %{foo: literal("bar")}}
  iex> literal({:ok, "bar"})
  %Type.Tuple{elements: [:ok, literal("bar")]}
  ```

  ### Key functions:

  #### comparison

  All literals are arranged in erlang term order, and less than all general
  types in the same class of type.

  ```elixir
  iex> import Type, only: :macros
  iex> Type.compare(literal([:foo, :bar]), literal([:foo, :baz]))
  :lt
  iex> Type.compare(literal([:foo, :bar]), list(:foo | :bar))
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
  iex> Type.usable_as(literal("foo"), %Type.Bitstring{unit: 24})
  {:error, %Type.Message{type: %Type.Literal{value: "foo"}, target: %Type.Bitstring{size: 24}}}
  ```

  """
end