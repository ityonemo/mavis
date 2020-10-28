defmodule Type.Tuple do
  @moduledoc """
  Represents tuple types.

  The associated struct has one parameter:
  - `:elements` which may be a list of types, corresponding to the ordered
    list of tuple element types.  May also be the atom `:any` which
    corresponds to the any tuple.

  ### Examples:

  - the any tuple is `%Type.Tuple{elements: :any}`
    ```
    iex> inspect %Type.Tuple{elements: :any}
    "tuple()"
    ```
  - generic tuples have their types as lists.
    ```
    iex> inspect %Type.Tuple{elements: [%Type{name: :atom}, %Type{name: :integer}]}
    "{atom(), integer()}"
    iex> inspect %Type.Tuple{elements: [:ok, %Type{name: :integer}]}
    "{:ok, integer()}"
    ```

  ### Key functions:

  #### comparison

  Longer tuples come after shorter tuples; tuples are then ordered using Cartesian
  dictionary order along the elements list.

  ```
  iex> Type.compare(%Type.Tuple{elements: []}, %Type.Tuple{elements: [:foo]})
  :lt
  iex> Type.compare(%Type.Tuple{elements: [:foo, 1..10]}, %Type.Tuple{elements: [:bar, 10..20]})
  ```

  #### intersection

  Tuples of different length do not intersect; the intersection is otherwise the Cartesian
  intersection of the elements.

  ```
  iex> Type.intersection(%Type.Tuple{elements: []}, %Type.Tuple{elements: [:ok, %Type{name: :integer}]})
  %Type{name: :none}

  iex> Type.intersection(%Type.Tuple{elements: [:ok, %Type{name: :integer}]},
  ...>                   %Type.Tuple{elements: [%Type{name: :atom}, 1..10]})
  %Type.Tuple{elements: [:ok, 1..10]}
  ```

  #### union

  Only tuple types of the same length can be non-trivially unioned, and then, only if
  one tuple type is a subtype of the other, and they must be identical across all but
  one dimension.

  ```
  iex> Type.union(%Type.Tuple{elements: [:ok, 11..20]},
  ...>           %Type.Tuple{elements: [:ok, 1..10]})
  %Type.Tuple{elements: [:ok, 1..20]}
  ```

  #### subtype?

  A tuple type is the subtype of another if its types are subtypes of the other
  across all Cartesian dimensions.

  ```
  iex> Type.subtype?(%Type.Tuple{elements: [:ok, 1..10]},
  ...>               %Type.Tuple{elements: [%Type{name: :atom}, %Type{name: :integer}]})
  true
  ```

  #### usable_as

  A tuple type is usable as another if it each of its elements are usable as
  the other across all Cartesian dimensions.  If any element is disjoint, then
  it is not usable.

  ```
  iex> Type.usable_as(%Type.Tuple{elements: [:ok, 1..10]},
  ...>                %Type.Tuple{elements: [%Type{name: :atom}, %Type{name: :integer}]})
  :ok
  iex> Type.usable_as(%Type.Tuple{elements: [:ok, %Type{name: :integer}]},
  ...>                %Type.Tuple{elements: [%Type{name: :atom}, 1..10]})
  {:maybe, [%Type.Message{type: %Type.Tuple{elements: [:ok, %Type{name: :integer}]},
                          target: %Type.Tuple{elements: [%Type{name: :atom}, 1..10]}}]}
  iex> Type.usable_as(%Type.Tuple{elements: [:ok, %Type{name: :integer}]},
  ...>                %Type.Tuple{elements: [:error, 1..10]})
  {:error, %Type.Message{type: %Type.Tuple{elements: [:ok, %Type{name: :integer}]},
                         target: %Type.Tuple{elements: [:error, 1..10]}}}
  ```

  """

  @enforce_keys [:elements]
  defstruct @enforce_keys

  @type t :: %__MODULE__{elements: [Type.t] | :any}

  defimpl Type.Properties do
    import Type, only: :macros

    use Type.Helpers

    alias Type.{Message, Tuple, Union}

    group_compare do
      def group_compare(%{elements: :any}, %Tuple{}), do: :gt
      def group_compare(_, %Tuple{elements: :any}), do:   :lt
      def group_compare(%{elements: e1}, %{elements: e2}) when length(e1) > length(e2), do: :gt
      def group_compare(%{elements: e1}, %{elements: e2}) when length(e1) < length(e2), do: :lt
      def group_compare(tuple1, tuple2) do
        tuple1.elements
        |> Enum.zip(tuple2.elements)
        |> Enum.each(fn {t1, t2} ->
          compare = Type.compare(t1, t2)
          unless compare == :eq do
            throw compare
          end
        end)
        :eq
      catch
        compare when compare in [:gt, :lt] -> compare
      end
    end

    usable_as do
      # any tuple can be used as an any tuple
      def usable_as(_, %Tuple{elements: :any}, _meta), do: :ok

      # the any tuple maybe can be used as any tuple
      def usable_as(challenge = %{elements: :any}, target = %Tuple{}, meta) do
        {:maybe, [Message.make(challenge, target, meta)]}
      end

      def usable_as(challenge = %{elements: ce}, target = %Tuple{elements: te}, meta)
          when length(ce) == length(te) do
        ce
        |> Enum.zip(te)
        |> Enum.map(fn {c, t} -> Type.usable_as(c, t, meta) end)
        |> Enum.reduce(&Type.ternary_and/2)
        |> case do
          :ok -> :ok
          # TODO: make our type checking nested, should be possible here.
          {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
          {:error, _} -> {:error, Message.make(challenge, target, meta)}
        end
      end
    end

    intersection do
      def intersection(%{elements: :any}, b = %Tuple{}), do: b
      def intersection(a, %Tuple{elements: :any}), do: a
      def intersection(%{elements: e1}, %Tuple{elements: e2}) when length(e1) == length(e2) do
        elements = e1
        |> Enum.zip(e2)
        |> Enum.map(fn {t1, t2} ->
          case Type.intersection(t1, t2) do
            builtin(:none) -> throw :mismatch
            any -> any
          end
        end)

        %Tuple{elements: elements}
      catch
        :mismatch ->
          builtin(:none)
      end
    end

    subtype do
      # can't simply forward to usable_as, because any of the encapsulated
      # types might have a usable_as rule that isn't strictly subtype?
      def subtype?(_tuple_type, %Tuple{elements: :any}), do: true
      # same nonempty is okay
      def subtype?(%{elements: el_c}, %Tuple{elements: el_t})
        when length(el_c) == length(el_t) do

        el_c
        |> Enum.zip(el_t)
        |> Enum.all?(fn {c, t} -> Type.subtype?(c, t) end)

      end
      def subtype?(tuple, %Union{of: types}) do
        Enum.any?(types, &Type.subtype?(tuple, &1))
      end
    end
  end

  defimpl Inspect do
    import Type, only: :macros
    def inspect(%{elements: :any}, _opts) do
      "tuple()"
    end
    def inspect(%{elements: [builtin(:module), builtin(:atom), 0..255]}, _opts) do
      "mfa()"
    end
    def inspect(%{elements: elements}, opts) do
      elements
      |> List.to_tuple()
      |> Inspect.inspect(opts)
    end
  end

end
