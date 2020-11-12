defmodule Type.Tuple do
  @moduledoc """
  Represents tuple types.

  The associated struct has one parameter:
  - `:elements` which may be a list of types, corresponding to the ordered
    list of tuple element types.

  ### Deviations from standard Erlang/Elixir:

  Mavis introduces a new type (that is not expressible via dialyzer).
  This is a tuple with minimum arity (`n`), this is represented by putting
  the tuple `{:min, n}` in the `:elements` field.  The properties of
  this type should be self-explanatory.  The `{:min, 0}` tuple is
  equvalent to the standard Erlang type `{...}`, aka `any tuple`

  ### Examples:

  - the any tuple is `%Type.Tuple{elements: {:min, 0}}`

    ```
    iex> inspect %Type.Tuple{elements: {:min, 0}}
    "tuple()"
    ```

  - A tuple of minimum size is represented as follows:

    ```
    iex> inspect %Type.Tuple{elements: {:min, 2}}
    "tuple({...(min: 2)})"
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
  %Type.Tuple{elements: {:min, 0}}
  iex> tuple {...(min: 2)}
  %Type.Tuple{elements: {:min, 2}}
  iex> tuple {:ok, builtin(:integer)}
  %Type.Tuple{elements: [:ok, builtin(:integer)]}
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
  iex> Type.intersection(tuple({}), tuple({:ok, builtin(:integer)}))
  %Type{name: :none}
  iex> Type.intersection(tuple({:ok, builtin(:integer)}), tuple({builtin(:atom), 1..10}))
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
  iex> Type.subtype?(tuple({:ok, 1..10}), tuple({builtin(:atom), builtin(:integer)}))
  true
  iex> Type.subtype?(tuple({:ok, 1..10}), tuple({...(min: 2)}))
  true
  iex> Type.subtype?(tuple({:ok, 1..10}), tuple({...(min: 3)}))
  false
  ```

  #### usable_as

  A tuple type is usable as another if it each of its elements are usable as
  the other across all Cartesian dimensions.  If any element is disjoint, then
  it is not usable.

  ```
  iex> import Type, only: :macros
  iex> Type.usable_as(tuple({:ok, 1..10}), tuple({builtin(:atom), builtin(:integer)}))
  :ok
  iex> Type.usable_as(tuple({:ok, builtin(:integer)}), tuple({builtin(:atom), 1..10}))
  {:maybe, [%Type.Message{type: tuple({:ok, builtin(:integer)}),
                          target: tuple({builtin(:atom), 1..10})}]}
  iex> Type.usable_as(tuple({:ok, builtin(:integer)}), tuple({:error, 1..10}))
  {:error, %Type.Message{type: tuple({:ok, builtin(:integer)}),
                         target: tuple({:error, 1..10})}}
  ```

  """

  @enforce_keys [:elements]
  defstruct @enforce_keys

  @type t :: %__MODULE__{elements: [Type.t] | {:min, non_neg_integer}}

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

  completes full analysis in a single pass of the function.

  Used in common between tuples and function parameters.
  """
  def merge(bigger, smaller), do: merge_helper(bigger, smaller, {[], true, 0})

  defp merge_helper(_, _, {_, false, disjoint}) when disjoint > 1, do: nil
  defp merge_helper([b_hd | b_tl], [s_hd | s_tl], {so_far, subtype?, disjoint}) do
    subtype? = subtype? and Type.subtype?(s_hd, b_hd)
    disjoint = if s_hd == b_hd, do: disjoint, else: disjoint + 1
    merged = Type.union(b_hd, s_hd)

    merge_helper(b_tl, s_tl, {[merged | so_far], subtype?, disjoint})
  end
  defp merge_helper([], [], {list, _, _}), do: Enum.reverse(list)
  defp merge_helper(_, _, _), do: nil # if the two lists are not of equal length.

  @doc """
  returns the tuple type at the (0-indexed) tuple slot.

  ```
  iex> import Type, only: :macros
  iex> Type.Tuple.elem(tuple({:ok, builtin(:pos_integer)}), 1)
  %Type{name: :pos_integer}
  ```
  """
  def elem(%__MODULE__{elements: elements}, index) when index < length(elements) do
    Enum.at(elements, index)
  end

  defimpl Type.Properties do
    import Type, only: :macros

    use Type.Helpers

    alias Type.{Message, Tuple, Union}

    group_compare do
      def group_compare(%{elements: {:min, m}}, %{elements: {:min, n}})
        when n > m,                                 do: :gt
      def group_compare(%{elements: {:min, m}}, %{elements: {:min, n}})
        when m > n,                                 do: :lt
      def group_compare(%{elements: {:min, _}}, _), do: :gt
      def group_compare(_, %{elements: {:min, _}}), do: :lt

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
      # lesser minimum sized tuples are maybes.
      def usable_as(challenge = %{elements: {:min, m}},
                    target = %Tuple{elements: {:min, n}},
                    meta) do
        if m >= n, do: :ok, else: {:maybe, [Message.make(challenge, target, meta)]}
      end

      # a minimum tuple maybe can be used as a tuple if the sizes are okay
      def usable_as(challenge = %{elements: {:min, m}}, target = %Tuple{}, meta) do
        if m <= length(target.elements) do
          {:maybe, [Message.make(challenge, target, meta)]}
        else
          {:error, Message.make(challenge, target, meta)}
        end
      end

      def usable_as(target, challenge = %Tuple{elements: {:min, m}}, meta) do
        if m <= length(target.elements) do
          :ok
        else
          {:error, Message.make(challenge, target, meta)}
        end
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
      def intersection(%{elements: {:min, m}}, %Tuple{elements: {:min, n}}) do
        %Tuple{elements: {:min, max(m, n)}}
      end
      def intersection(%{elements: {:min, m}}, tup = %Tuple{elements: e}) do
        if length(e) >= m, do: tup, else: builtin(:none)
      end
      def intersection(tup = %{elements: e}, %Tuple{elements: {:min, m}}) do
        if length(e) >= m, do: tup, else: builtin(:none)
      end
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
      # bigger minimums are more restrictive, so subtyping is >=
      def subtype?(%{elements: {:min, m}}, %Tuple{elements: {:min, n}}) do
        m >= n
      end
      def subtype?(%{elements: {:min, _}}, %Tuple{}), do: false
      def subtype?(%{elements: el}, %Tuple{elements: {:min, m}}) do
        length(el) >= m
      end
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
    import Inspect.Algebra
    def inspect(%{elements: {:min, 0}}, _opts) do
      "tuple()"
    end
    def inspect(%{elements: {:min, n}}, _opts) do
      "tuple({...(min: #{n})})"
    end
    def inspect(%{elements: [builtin(:module), builtin(:atom), 0..255]}, _opts) do
      "mfa()"
    end
    def inspect(%{elements: elements}, opts) do
      inner_contents = elements
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(", ")

      concat(["tuple({" | inner_contents] ++ ["})"])
    end
  end

end
