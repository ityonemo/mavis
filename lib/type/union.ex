defmodule Type.Union do
  @moduledoc """
  Represents the Union of two or more types.

  The associated struct has one field:
  - `:of` which is a list of all types that are being unioned.

  For performance purposes, Union keeps its subtypes in
  reverse-type-order.

  Type.Union implements both the enumerable protocol and the
  collectable protocol; if you collect into a union, it will return
  a `t:Type.t/0` result in general; it might not be a Type.Union struct:

  ```
  iex> Enum.into([1, 3], %Type.Union{})
  %Type.Union{of: [3, 1]}

  iex> inspect %Type.Union{of: [3, 1]}
  "1 | 3"

  iex> Enum.into([1..10, 11..20], %Type.Union{})
  1..20
  ```
  """

  defstruct [of: []]
  @type t :: %__MODULE__{of: [Type.t, ...]}
  @type t(type) :: %__MODULE__{of: [type, ...]}
  
  import Type, only: :macros

  @spec collapse(t) :: Type.t
  @doc false
  def collapse(%__MODULE__{of: []}), do: builtin(:none)
  def collapse(%__MODULE__{of: [singleton]}), do: singleton
  def collapse(union), do: union

  @spec merge(t, Type.t) :: t
  @doc false
  # special case merging a union with another union.
  def merge(%{of: into}, %__MODULE__{of: list}) do
    %__MODULE__{of: merge_raw(into, list)}
  end
  def merge(%{of: list}, type) do
    %__MODULE__{of: merge_raw(list, [type])}
  end

  # merges: types in argument1 into the list of argument2
  # argument2 is required to be in DESCENDING order
  # returns the fully merged types, in ASCENDING order
  @spec merge_raw([Type.t], [Type.t]) :: [Type.t]
  defp merge_raw(list, [head | rest]) do
    {new_list, retries} = fold(head, Enum.reverse(list), [])
    merge_raw(new_list, retries ++ rest)
  end
  defp merge_raw(list, []) do
    Enum.sort(list, {:desc, Type})
  end

  # folds argument 1 into the list of argument2.
  # argument 3, which is the stack, contains the remaining types in ASCENDING order.
  @spec fold(Type.t, [Type.t], [Type.t]) :: {[Type.t], [Type.t]}
  defp fold(type, [head | rest], stack) do
    with order when order in [:gt, :lt] <- Type.compare(head, type),# |> IO.inspect(label: "66"),
         retries when is_list(retries) <- type_merge(order, head, type) do
      {unroll(rest, stack), retries}
    else
      :eq ->
        {unroll(rest, [head | stack]), []}
      :nomerge ->
        fold(type, rest, [head | stack])
    end
  end
  defp fold(type, [], stack) do
    {[type | stack], []}
  end

  defp unroll([], stack), do: stack
  defp unroll([head | rest], stack), do: unroll(rest, [head | stack])

  @spec type_merge(:gt | :lt, Type.t, Type.t) :: :nomerge | [Type.t]
  defp type_merge(:gt, a, b), do: type_merge(b, a)
  defp type_merge(:lt, a, b), do: type_merge(a, b)

  # attempts to merge a two types into each other.
  # second argument is guaranteed to be greater in type order than
  # the first argument.
  @spec type_merge(Type.t, Type.t) :: :nomerge | [Type.t]
  @doc false
  # integers and ranges
  defp type_merge(a, b) when b == a + 1,           do: [a..b]
  defp type_merge(a, b..c) when b == a + 1,        do: [a..c]
  defp type_merge(b, a..c) when a <= b and b <= c, do: [a..c]
  defp type_merge(a..b, c) when c == b + 1,        do: [a..c]
  defp type_merge(a..b, c..d) when c <= b + 1,     do: [a..d]

  # ranges with negative integer (note these ranges are > neg_integer())
  defp type_merge(builtin(:neg_integer), _..0) do
    [builtin(:neg_integer), 0]
  end
  defp type_merge(builtin(:neg_integer), a..b) when a < 0 and b > 0 do
    [builtin(:neg_integer), 0..b]
  end
  # negative integers with integers and ranges
  defp type_merge(i, builtin(:neg_integer)) when is_integer(i) and i < 0 do
    [builtin(:neg_integer)]
  end
  defp type_merge(_..b, builtin(:neg_integer)) when b < 0 do
    [builtin(:neg_integer)]
  end

  # positive integers with integers and ranges.  Note that positive integer
  # will always be greater than these ranges.
  defp type_merge(i, builtin(:pos_integer)) when is_integer(i) and i > 0 do
    [builtin(:pos_integer)]
  end
  defp type_merge(a.._, builtin(:pos_integer)) when a > 0 do
    [builtin(:pos_integer)]
  end
  defp type_merge(0.._, builtin(:pos_integer)) do
    [0, builtin(:pos_integer)]
  end
  defp type_merge(a..b, builtin(:pos_integer)) when b > 0 do
    [a..0, builtin(:pos_integer)]
  end

  # atom literals
  defp type_merge(atom, builtin(:atom)) when is_atom(atom) do
    [builtin(:atom)]
  end

  # tuples
  alias Type.Tuple
  defp type_merge(%Tuple{}, builtin(:tuple)) do
    [builtin(:tuple)]
  end
  defp type_merge(lhs = %Tuple{}, rhs = %Tuple{}) do
    if merged_elements = Tuple.merge(rhs.elements, lhs.elements) do
      [%Tuple{elements: merged_elements}]
    else
      :nomerge
    end
  end

  # lists
  alias Type.List
  # matching finals
  defp type_merge(%List{type: tl, nonempty: nl, final: final},
                  %List{type: tr, nonempty: nr, final: final}) do
    [%List{type: Type.union(tl, tr), nonempty: nl and nr, final: final}]
  end
  # matching types
  defp type_merge(%List{type: type, nonempty: nl, final: fl},
                  %List{type: type, nonempty: nr, final: fr}) do

    [%List{type: type, nonempty: nl and nr, final: Type.union(fl, fr)}]
  end
  defp type_merge([], %List{type: type, final: final}) do
    # technically this shouldn't be necessary since all nonempty lists must
    # be able to have final []
    [%List{type: type, final: Type.union(final, [])}]
  end
  defp type_merge(%List{type: type, final: final, nonempty: true}, []) do
    [%List{type: type, final: Type.union(final, []), nonempty: false}]
  end
  defp type_merge(l1 = %List{}, l2 = %List{}) do
    if merge = Tuple.merge([l1.type, l1.final], [l2.type, l2.final]) do
      [type, final] = merge
      [%List{type: type, final: final, nonempty: l1.nonempty and l2.nonempty}]
    else
      :nomerge
    end
  end

  # maps
  alias Type.Map
  defp type_merge(left = %Map{}, right = %Map{}) do
    # for maps, it's the subset relationship, but it might need to admit
    # that some keys have to be turned into optional.
    optionalized_right = Map.optionalize(right, keep: Elixir.Map.keys(left.required))
    cond do
      Type.subtype?(left, right) ->
        [right]
      Type.subtype?(left, optionalized_right) ->
        [optionalized_right]
      true -> :nomerge
    end
  end

  # functions
  alias Type.Function
  defp type_merge(%Function{params: p, return: left},
                  %Function{params: p, return: right}) do
    [%Function{params: p, return: Type.union(left, right)}]
  end

  # bitstrings and binaries
  alias Type.Bitstring
  defp type_merge(_, %Bitstring{unit: 0}), do: :nomerge
  defp type_merge(left = %Bitstring{unit: 0}, right = %Bitstring{}) do
    if rem(right.size - left.size, right.unit) == 0 do
      [right]
    else
      :nomerge
    end
  end
  defp type_merge(left = %Bitstring{}, right = %Bitstring{}) do
    if rem(left.size - right.size, Integer.gcd(left.unit, right.unit)) == 0 do
      [right]
    else
      :nomerge
    end
  end
  defp type_merge(%Type{module: String, name: :t}, remote(String.t)) do
    [remote(String.t)]
  end
  defp type_merge(%Type{module: String, name: :t, params: [left]},
                  %Type{module: String, name: :t, params: [right]}) do
    lengths = Type.union(left, right)
    [remote(String.t(lengths))]
  end
  defp type_merge(%Type{module: String, name: :t, params: []},
                  %Bitstring{size: 0, unit: unit})
                  when unit in [1, 2, 4, 8] do
    [%Bitstring{unit: unit}]
  end
  defp type_merge(%Type{module: String, name: :t, params: [bytes]},
                 bitstring = %Bitstring{size: size, unit: unit}) do
    bytes
    |> case do
      i when is_integer(i) -> [i]
      range = _.._ -> range
      %Type.Union{of: ints} -> ints
    end
    |> Enum.split_with(&(rem(&1 * 8 - size, unit) == 0))
    |> case do
      {[], _} -> :nomerge
      {_, keep} ->
        keep_type = Type.union(keep)
        [bitstring, remote(String.t(keep_type))]
    end
  end

  # any
  defp type_merge(_, builtin(:any)) do
    [builtin(:any)]
  end
  defp type_merge(_, _), do: :nomerge

  defimpl Type.Properties do
    import Type, only: :macros
    import Type.Helpers

    alias Type.Union

    def compare(union, %Type.Function.Var{constraint: type}) do
      case Type.compare(union, type) do
        :eq -> :gt
        order -> order
      end
    end
    def compare(union, %Type.Opaque{type: type}) do
      case Type.compare(union, type) do
        :eq -> :gt
        order -> order
      end
    end
    def compare(%{of: llist}, %Union{of: rlist}) do
      union_list_compare(llist, rlist)
    end
    def compare(%{of: [first | _]}, type) do
      case Type.compare(first, type) do
        :eq -> :gt
        order -> order
      end
    end

    defp union_list_compare([], []), do: :eq
    defp union_list_compare([], _), do: :lt
    defp union_list_compare(_, []), do: :gt
    defp union_list_compare([lh | lrest], [rh | rrest]) do
      case Type.compare(lh, rh) do
        :eq -> union_list_compare(lrest, rrest)
        order -> order
      end
    end

    def typegroup(%{of: [first | _]}) do
      Type.Properties.typegroup(first)
    end

    def usable_as(challenge, target, meta) do
      challenge.of
      |> Enum.map(&Type.usable_as(&1, target, meta))
      |> Enum.reduce(fn
        # TO BE REPLACED WITH SOMETHING MORE SOPHISTICATED.
        :ok, :ok                 -> :ok
        :ok, {:maybe, _}         -> {:maybe, nil}
        :ok, {:error, _}         -> {:maybe, nil}
        {:maybe, _}, :ok         -> {:maybe, nil}
        {:error, _}, :ok         -> {:maybe, nil}
        {:maybe, _}, {:maybe, _} -> {:maybe, nil}
        {:maybe, _}, {:error, _} -> {:maybe, nil}
        {:error, _}, {:maybe, _} -> {:maybe, nil}
        {:error, _}, {:error, _} -> {:error, nil}
      end)
      |> case do
        :ok -> :ok
        {:maybe, _} -> {:maybe, [Type.Message.make(challenge, target, meta)]}
        {:error, _} -> {:error, Type.Message.make(challenge, target, meta)}
      end
    end

    intersection do
      def intersection(lunion, runion = %Type.Union{}) do
        lunion.of
        |> Enum.map(&Type.intersection(runion, &1))
        |> Enum.reject(&(&1 == builtin(:none)))
        |> Enum.into(%Type.Union{})
      end
      def intersection(union = %{}, ritem) do
        union.of
        |> Enum.map(&Type.intersection(&1, ritem))
        |> Enum.reject(&(&1 == builtin(:none)))
        |> Enum.into(%Type.Union{})
      end
    end

    subtype do
      def subtype?(%{of: types}, target) do
        Enum.all?(types, &Type.subtype?(&1, target))
      end
    end
  end

  defimpl Collectable do
    alias Type.Union

    def into(original) do
      collector_fun = fn
        union, {:cont, elem} ->
          Union.merge(union, elem)
        union, :done -> Union.collapse(union)
        _set, :halt -> :ok
      end

      {original, collector_fun}
    end
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(%{of: types}, opts) do
      cond do
        # override for boolean
        rest = type_has(types, [true, false]) ->
          override(rest, :boolean, opts)

        # override for identifier
        rest = type_has(types, [builtin(:reference), builtin(:port), builtin(:pid)]) ->
          override(rest, :identifier, opts)

        # override for iodata
        rest = type_has(types, [builtin(:iolist), %Type.Bitstring{size: 0, unit: 8}]) ->
          override(rest, :iodata, opts)

        # override for number
        rest = type_has(types, [builtin(:float), builtin(:neg_integer), 0, builtin(:pos_integer)]) ->
          override(rest, :number, opts)

        # override for integers
        rest = type_has(types, [builtin(:neg_integer), 0, builtin(:pos_integer)]) ->
          override(rest, :integer, opts)

        # override for timeout
        rest = type_has(types, [0, builtin(:pos_integer), :infinity]) ->
          override(rest, :timeout, opts)

        # override for non_neg_integer
        rest = type_has(types, [0, builtin(:pos_integer)]) ->
          override(rest, :non_neg_integer, opts)

        rest = type_has(types, [-1..0, builtin(:pos_integer)]) ->
          type = override(rest, :non_neg_integer, opts)
          concat(["-1", " | ", type])

        (range = Enum.find(types, &match?(_..0, &1))) && builtin(:pos_integer) in types ->
          type = types
          |> Kernel.--([range, builtin(:pos_integer)])
          |> override(:non_neg_integer, opts)

          concat(["#{range.first}..-1", " | ", type])

        true -> normal_inspect(types, opts)
      end
    end

    defp type_has(types, query) do
      if Enum.all?(query, &(&1 in types)), do: types -- query
    end

    defp override([], name, _opts) do
      "#{name}()"
    end
    defp override(types, name, opts) do
      concat(["#{name}()", " | ",
        to_doc(%Type.Union{of: types}, opts)])
    end

    defp normal_inspect(list, opts) do
      list
      |> Enum.reverse
      |> Enum.map(&to_doc(&1, opts))
      |> Enum.intersperse(" | ")
      |> concat
    end
  end
end
