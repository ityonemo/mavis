defmodule Type.Tuple do
  @moduledoc """
  Represents tuple types.

  The associated struct has two parameters:
  - `:elements` which may be a list of types, corresponding to the ordered
    list of tuple element types.
  - `:fixed` which is false if the total number of elements is not known,
    but must be at least as many as are in the `:elements` list.

  ### Deviations from standard Erlang/Elixir:

  Mavis introduces a new type (that is not expressible via dialyzer).
  This is a tuple with minimum arity (`n`), this is represented by setting
  the `:fixed` field to false.  The standard erlang type `any tuple` has an
  empty list as its elements and `fixed: false`.

  ### Examples:

  - the any tuple is `%Type.Tuple{elements: [], fixed: false}`

    ```elixir
    iex> inspect %Type.Tuple{elements: [], fixed: false}
    "tuple()"
    ```

  - A tuple of minimum size is represented as follows:

    ```elixir
    iex> inspect %Type.Tuple{elements: [any(), any()], fixed: false}
    "tuple({any(), any(), ...})"
    ```

  - generic tuples have their types as lists.
    ```
    iex> inspect %Type.Tuple{elements: [%Type{name: :atom}, %Type{name: :integer}]}
    "tuple({atom(), integer()})"
    iex> inspect %Type.Tuple{elements: [:ok, %Type{name: :integer}]}
    "tuple({:ok, integer()})"
    ```

  ### Shortcut Form

  The `Type` module lets you specify a tuple using "shortcut form" via the
  `Type.tuple/1` macro:

  ```
  iex> import Type, only: :macros
  iex> tuple {...}
  %Type.Tuple{elements: [], fixed: false}
  iex> tuple {any(), any(), ...}
  %Type.Tuple{elements: [any(), any()], fixed: false}
  iex> tuple {:ok, integer()}
  %Type.Tuple{elements: [:ok, integer()]}
  ```

  ### Key functions:

  #### comparison

  Longer tuples come after shorter tuples; tuples are then ordered using Cartesian
  dictionary order along the elements list.

  ```
  iex> import Type, only: :macros
  iex> Type.compare(tuple({}), tuple({:foo}))
  :lt
  iex> Type.compare(tuple({:foo, 1..10}), tuple({:bar, 10..20}))
  :gt
  ```

  #### intersection

  Tuples of different length do not intersect; the intersection is otherwise the Cartesian
  intersection of the elements.

  ```
  iex> import Type, only: :macros
  iex> Type.intersection(tuple({}), tuple({:ok, integer()}))
  %Type{name: :none}
  iex> Type.intersection(tuple({:ok, integer()}), tuple({atom(), 1..10}))
  %Type.Tuple{elements: [:ok, 1..10]}
  ```

  #### union

  Only tuple types of the same length can be non-trivially unioned, and then, only if
  one tuple type is a subtype of the other, and they must be identical across all but
  one dimension.

  ```
  iex> import Type, only: :macros
  iex> Type.union(tuple({:ok, 11..20}), tuple({:ok, 1..10}))
  %Type.Tuple{elements: [:ok, 1..20]}
  ```

  #### subtype?

  A tuple type is the subtype of another if its types are subtypes of the other
  across all Cartesian dimensions, but is not the subtype of a tuple that
  requires more minimum values.

  ```
  iex> import Type, only: :macros
  iex> Type.subtype?(tuple({:ok, 1..10}), tuple({atom(), integer()}))
  true
  iex> Type.subtype?(tuple({:ok, 1..10}), tuple({any(), any(), ...}))
  true
  iex> Type.subtype?(tuple({:ok, 1..10}), tuple({any(), any(), any(), ...}))
  false
  ```

  #### usable_as

  A tuple type is usable as another if it each of its elements are usable as
  the other across all Cartesian dimensions.  If any element is disjoint, then
  it is not usable.

  ```
  iex> import Type, only: :macros
  iex> Type.usable_as(tuple({:ok, 1..10}), tuple({atom(), integer()}))
  :ok
  iex> Type.usable_as(tuple({:ok, integer()}), tuple({atom(), 1..10}))
  {:maybe, [%Type.Message{type: tuple({:ok, integer()}),
                          target: tuple({atom(), 1..10})}]}
  iex> Type.usable_as(tuple({:ok, integer()}), tuple({:error, 1..10}))
  {:error, %Type.Message{type: tuple({:ok, integer()}),
                         target: tuple({:error, 1..10})}}
  ```

  """

  @enforce_keys [:elements]
  defstruct @enforce_keys ++ [fixed: true]

  @type t :: %__MODULE__{
    elements: [Type.t],
    fixed: boolean
  }
  @type t(type) :: %__MODULE__{
    elements: [type],
    fixed: true
  }

  @doc """
  a utility function which takes two type lists and ascertains if they
  can be merged as tuples.

  returns the merged list if the two lists are mergeable.  This follows
  from one of two conditions:

  - each type in the "narrower" type list is a subtype of the corresponding
    "broader" type list
  - all types are equal except for one

  returns nil if the two lists are not mergeable; returns the merged
  list if the two lists are mergeable.

  strict toggles whether a non-fixed tuple is allowed to be the first
  parameter.

  completes full analysis in a single pass of the function.

  Used in common between tuples and list parameters.
  """
  def merge(bigger, smaller, strict \\ true) do
    merge_helper(bigger, smaller, strict, {[], true, 0})
  end

  defp merge_helper(_, _, _, {_, false, disjoint}) when disjoint > 1, do: nil
  defp merge_helper([b_hd | b_tl], [s_hd | s_tl], strict, {so_far, subtype?, disjoint}) do
    subtype? = subtype? and Type.subtype?(s_hd, b_hd)
    disjoint = if s_hd == b_hd, do: disjoint, else: disjoint + 1
    merged = Type.union(b_hd, s_hd)

    merge_helper(b_tl, s_tl, strict, {[merged | so_far], subtype?, disjoint})
  end
  defp merge_helper([], [], true,  {list, _, _}), do: Enum.reverse(list)
  defp merge_helper([], _,  false, {list, _, _}), do: Enum.reverse(list)
  defp merge_helper(_, _, _, _), do: nil # if the two lists are not of equal length.

  @doc """
  returns the tuple type at the (0-indexed) tuple slot.

  ```
  iex> import Type, only: :macros
  iex> Type.Tuple.elem(tuple({:ok, pos_integer()}), 1)
  %Type{name: :pos_integer}
  ```
  """
  def elem(%__MODULE__{elements: elements}, index) when index < length(elements) do
    Enum.at(elements, index)
  end

  defimpl Type.Algebra do
    import Type, only: :macros

    use Type.Helpers

    alias Type.{Message, Tuple, Union}

    group_compare do
      def group_compare(%{fixed: false}, %{fixed: true}), do: :gt
      def group_compare(%{fixed: true}, %{fixed: false}), do: :lt
      def group_compare(%{elements: e1, fixed: false}, %{elements: e2})
        when length(e1) > length(e2), do: :lt
      def group_compare(%{elements: e1, fixed: false}, %{elements: e2})
        when length(e1) < length(e2), do: :gt
      def group_compare(%{elements: e1, fixed: true}, %{elements: e2})
        when length(e1) > length(e2), do: :gt
      def group_compare(%{elements: e1, fixed: true}, %{elements: e2})
        when length(e1) < length(e2), do: :lt
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
      def usable_as(challenge = %{elements: ce, fixed: true}, target = %Tuple{elements: te, fixed: true}, meta)
          when length(ce) != length(te) do
        {:error, Message.make(challenge, target, meta)}
      end
      def usable_as(challenge = %{elements: ce, fixed: false}, target = %Tuple{elements: te, fixed: true}, meta)
          when length(ce) > length(te) do
        {:error, Message.make(challenge, target, meta)}
      end
      def usable_as(challenge = %{elements: ce, fixed: true}, target = %Tuple{elements: te, fixed: false}, meta)
          when length(ce) < length(te) do
        {:error, Message.make(challenge, target, meta)}
      end
      def usable_as(challenge = %{elements: ce, fixed: cf}, target = %Tuple{elements: te, fixed: tf}, meta) do
        ce
        |> zipfill(te, any())
        |> Enum.map(fn {c, t} -> Type.usable_as(c, t, meta) end)
        |> Enum.reduce(:ok, &Type.ternary_and/2)
        |> case do
          :ok when not cf and (tf or length(ce) < length(te)) ->
            {:maybe, [Message.make(challenge, target, meta)]}
          :ok -> :ok
          # TODO: make our type checking nested, should be possible here.
          {:maybe, _} -> {:maybe, [Message.make(challenge, target, meta)]}
          {:error, _} -> {:error, Message.make(challenge, target, meta)}
        end
      end
    end

    intersection do
      def intersection(%{elements: e1, fixed: true}, %Tuple{elements: e2, fixed: false})
        when length(e1) < length(e2), do: none()
      def intersection(%{elements: e1, fixed: false}, %Tuple{elements: e2, fixed: true})
        when length(e2) < length(e1), do: none()
      def intersection(%{elements: e1, fixed: true}, %Tuple{elements: e2, fixed: true})
        when length(e1) != length(e2), do: none()
      def intersection(%{elements: e1, fixed: f1}, %Tuple{elements: e2, fixed: f2}) do
        elements = e1
        |> zipfill(e2, any())
        |> Enum.map(fn {t1, t2} ->
          case Type.intersection(t1, t2) do
            none() -> throw :mismatch
            any -> any
          end
        end)

        %Tuple{elements: elements, fixed: f1 or f2}
      catch
        :mismatch ->
          none()
      end
    end

    # like Enum.zip, but only works on lists, and fills up the other
    # list with a value, instead of stopping when one list is exhausted.
    defp zipfill(lst1, lst2, fill, so_far \\ [])
    defp zipfill([h1 | t1], [h2 | t2], fill, so_far) do
      zipfill(t1, t2, fill, [{h1, h2} | so_far])
    end
    defp zipfill([], [h2 | t2], fill, so_far) do
      zipfill([], t2, fill, [{fill, h2} | so_far])
    end
    defp zipfill([h1 | t1], [], fill, so_far) do
      zipfill(t1, [], fill, [{h1, fill} | so_far])
    end
    defp zipfill([], [], _fill, so_far), do: Enum.reverse(so_far)

    subtype do
      def subtype?(%{elements: e1, fixed: true}, %Tuple{elements: e2, fixed: false})
        when length(e1) < length(e2), do: false
      def subtype?(%{elements: e1, fixed: false}, %Tuple{elements: e2, fixed: true})
        when length(e2) < length(e1), do: false
      def subtype?(%{elements: e1, fixed: true}, %Tuple{elements: e2, fixed: true})
        when length(e1) != length(e2), do: false
      def subtype?(%{elements: e1}, %Tuple{elements: e2}) when length(e1) >= length(e2) do
        e1
        |> zipfill(e2, any())
        |> Enum.all?(fn {c, t} -> Type.subtype?(c, t) end)
      end
      def subtype?(tuple, %Union{of: types}) do
        Enum.any?(types, &Type.subtype?(tuple, &1))
      end
    end

    def normalize(%Tuple{fixed: false}) do
      %Tuple{elements: [], fixed: false}
    end
    def normalize(%Tuple{elements: elements}) do
      %Tuple{elements: Enum.map(elements, &Type.normalize/1)}
    end
    def normalize(type), do: super(type)
  end

  defimpl Inspect do
    import Type, only: :macros
    import Inspect.Algebra
    def inspect(%{elements: [], fixed: false}, _opts) do
      "tuple()"
    end
    def inspect(%{elements: [module(), atom(), 0..255], fixed: true}, _opts) do
      "mfa()"
    end
    def inspect(%{elements: elements, fixed: fixed}, opts) do
      inner_contents = elements
      |> Enum.map(&to_doc(&1, opts))
      |> Kernel.++(if fixed, do: [], else: ["..."])
      |> Enum.intersperse(", ")

      concat(["tuple({" | inner_contents] ++ ["})"])
    end
  end
end
