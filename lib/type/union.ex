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

  import Type, only: :macros

  @spec collapse(t) :: Type.t
  @doc false
  def collapse(%__MODULE__{of: []}), do: builtin(:none)
  def collapse(%__MODULE__{of: [singleton]}), do: singleton
  def collapse(union), do: union

  @spec merge(t, Type.t) :: t
  @doc false
  # special case merging a union with another union.
  def merge(union = %__MODULE__{}, %__MODULE__{of: list}) do
    Enum.reduce(list, union, &merge(&2, &1))
  end
  def merge(union = %__MODULE__{of: list}, type = %Type{module: String, name: :t}) do
    %{union | of: merge(list, type, [])}
  end
  def merge(union = %__MODULE__{of: list}, type) when is_remote(type) do
    %{union | of: list ++ [type]}
  end
  def merge(union = %__MODULE__{of: list}, type) do
    %{union | of: merge(list, type, [])}
  end

  @spec merge([Type.t], Type.t, [Type.t]) :: [Type.t]
  @doc false
  defp merge([top | rest], type, stack) do
    with cmp when cmp != :eq <- Type.compare(top, type),
         {_, {new_type, new_list}} <- {cmp, type_merge(cmp, top, type, rest)} do
      merge(new_list, new_type, stack)
    else
      :eq -> unroll([top | rest], stack)
      {:gt, :nomerge} -> merge(rest, type, [top | stack])
      {:lt, :nomerge} -> unroll([type, top | rest], stack)
    end
  end
  defp merge([], type, stack), do: unroll([type], stack)

  @spec unroll([Type.t], [Type.t]) :: [Type.t]
  # unrolls the stack of types-too-big back onto the rest of the list,
  # because we've completed the list.
  defp unroll(list, []), do: list
  defp unroll(list, [top | rest]), do: unroll([top | list], rest)

  @spec type_merge(:gt | :lt, Type.t, Type.t, [Type.t]) :: {Type.t, [Type.t]}
  @doc false
  def type_merge(:gt, top, type, rest) do
    type_merge([type | rest], top)
  end
  def type_merge(:lt, top, type, rest) do
    type_merge([top | rest], type)
  end

  @spec type_merge([Type.t], Type.t) :: {Type.t, [Type.t]} | :nomerge
  @doc false
  # integers and ranges
  def type_merge([a | rest], b) when b == a + 1 do
    {a..b, rest}
  end
  def type_merge([a | rest], b..c) when b == a + 1 do
    {a..c, rest}
  end
  def type_merge([b | rest], a..c) when a <= b and b <= c do
    {a..c, rest}
  end
  def type_merge([a..b | rest], c) when c == b + 1 do
    {a..c, rest}
  end
  def type_merge([a..b | rest], c..d) when c <= b + 1 do
    {a..d, rest}
  end
  # ranges with negative integer (note these ranges are > neg_integer())
  def type_merge([builtin(:neg_integer) | rest], _..0) do
    {0, [builtin(:neg_integer) | rest]}
  end
  def type_merge([builtin(:neg_integer) | rest], a..b) when a < 0 and b > 0 do
    {0..b, [builtin(:neg_integer) | rest]}
  end
  # negative integers with integers and ranges
  def type_merge([i | rest], builtin(:neg_integer)) when is_integer(i) and i < 0 do
    {builtin(:neg_integer), rest}
  end
  def type_merge([_..b | rest], builtin(:neg_integer)) when b < 0 do
    {builtin(:neg_integer), rest}
  end
  # positive integers with integers and ranges
  def type_merge([i | rest], builtin(:pos_integer)) when is_integer(i) and i > 0 do
    {builtin(:pos_integer), rest}
  end
  def type_merge([a.._ | rest], builtin(:pos_integer)) when a > 0 do
    {builtin(:pos_integer), rest}
  end
  def type_merge([0.._ | rest], builtin(:pos_integer)) do
    {0, [builtin(:pos_integer) | rest]}
  end
  def type_merge([a..b | rest], builtin(:pos_integer)) when b > 0 do
    {a..0, [builtin(:pos_integer) | rest]}
  end

  # atoms
  def type_merge([atom | rest], builtin(:atom)) when is_atom(atom) do
    {builtin(:atom), rest}
  end

  # tuples
  alias Type.Tuple
  def type_merge([%Tuple{} | rest], builtin(:tuple)) do
    {builtin(:tuple), rest}
  end
  def type_merge([lhs = %Tuple{} | rest], rhs = %Tuple{}) do
    merged_elements = lhs.elements
    |> Enum.zip(rhs.elements)
    |> Enum.map(fn
      {type, type} -> type
      {lh, rh} ->
        union = Type.union(lh, rh) |> IO.inspect(label: "148", structs: false)
        match?(%Type.Union{}, union) and (union.of == merge_parts(lh, rh)) and throw :nomerge
        union
    end)
    {%Tuple{elements: merged_elements}, rest}
  catch
    :nomerge -> :nomerge
  end

  # lists
  alias Type.List
  def type_merge(
      [%List{type: tl, nonempty: nl, final: final} | rest],
       %List{type: tr, nonempty: nr, final: final}) do

    {%List{type: Type.union(tl, tr),
           nonempty: nl and nr,
           final: final}, rest}
  end
  def type_merge(
    [%List{type: type, nonempty: nl, final: fl} | rest],
     %List{type: type, nonempty: nr, final: fr}) do

    {%List{type: type,
           nonempty: nl and nr,
           final: Type.union(fl, fr)}, rest}
  end
  def type_merge([[] | rest], %List{type: type, final: []}) do
    {list(type), rest}
  end
  def type_merge([%List{type: type, final: [], nonempty: true} | rest], []) do
    {list(type), rest}
  end

  # maps
  alias Type.Map
  def type_merge([left = %Map{} | rest], right = %Map{}) do
    # for maps, it's the subset relationship, but possibly
    # optionalized
    optionalized_right = Map.optionalize(right)
    cond do
      Type.subtype?(left, right) ->
        {right, rest}
      Type.subtype?(left, optionalized_right) ->
        {optionalized_right, rest}
      true -> :nomerge
    end
  end

  # functions
  alias Type.Function
  def type_merge([left = %Function{params: p} | rest], right = %Function{params: p}) do
    {%Function{params: p, return: Type.union(left.return, right.return)}, rest}
  end

  # bitstrings and binaries
  alias Type.Bitstring
  def type_merge(_, %Bitstring{unit: 0}), do: :nomerge
  def type_merge([left = %Bitstring{unit: 0} | rest], right = %Bitstring{}) do
    if rem(right.size - left.size, right.unit) == 0 do
      {right, rest}
    else
      :nomerge
    end
  end
  def type_merge([left = %Bitstring{} | rest], right = %Bitstring{}) do
    if rem(left.size - right.size, Integer.gcd(left.unit, right.unit)) == 0 do
      {right, rest}
    else
      :nomerge
    end
  end
  def type_merge([%Type{module: String, name: :t} | rest], right = remote(String.t)) do
    {right, rest}
  end
  def type_merge([%Type{module: String, name: :t, params: [left]} | rest],
                  %Type{module: String, name: :t, params: [right]}) do
    merge = Type.union(left, right)
    {remote(String.t(merge)), rest}
  end
  def type_merge([%Type{module: String, name: :t, params: []} | rest],
                 b = %Bitstring{size: 0, unit: unit})
                 when unit in [1, 2, 4, 8], do: {b, rest}
  def type_merge([%Type{module: String, name: :t, params: [p]} | rest],
                 b = %Bitstring{size: size, unit: unit}) do
    leftovers = p
    |> case do
      i when is_integer(i) -> [i]
      range = _.._ -> range
      %Type.Union{of: ints} -> ints
    end
    |> Enum.reject(&(rem(&1 * 8 - size, unit) == 0))
    |> Enum.map(&%Type{module: String, name: :t, params: [&1]})
    |> Enum.into(%Type.Union{})

    {leftovers, [b | rest]}
  end
  # any
  def type_merge([_ | rest], builtin(:any)) do
    {builtin(:any), rest}
  end
  def type_merge([_type | _rest], _top), do: :nomerge

  defimpl Type.Properties do
    import Type, only: :macros
    import Type.Helpers

    alias Type.Union

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
