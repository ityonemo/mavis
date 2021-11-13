defmodule Type.Union.Merge do

  import Type, only: :macros

  @spec type_merge(:gt | :lt, Type.t, Type.t) :: :nomerge | [Type.t]
  def type_merge(:gt, a, b), do: type_merge(b, a)
  def type_merge(:lt, a, b), do: type_merge(a, b)

  # attempts to merge two types into each other.
  # second argument is guaranteed to be greater in type order than
  # the first argument.
  @spec type_merge(Type.t, Type.t) :: :nomerge | [Type.t]
  @doc false
  # integers and ranges
  def type_merge(a, b) when b == a + 1,           do: [a..b]
  def type_merge(a, b..c) when b == a + 1,        do: [a..c]
  def type_merge(b, a..c) when a <= b and b <= c, do: [a..c]
  def type_merge(a..b, c) when c == b + 1,        do: [a..c]
  def type_merge(a..b, c..d) when c <= b + 1,     do: [a..d]

  # ranges with negative integer (note these ranges are > neg_integer())
  def type_merge(neg_integer(), _..0) do
    [neg_integer(), 0]
  end
  def type_merge(neg_integer(), a..b) when a < 0 and b > 0 do
    [neg_integer(), 0..b]
  end
  # negative integers with integers and ranges
  def type_merge(i, neg_integer()) when is_integer(i) and i < 0 do
    [neg_integer()]
  end
  def type_merge(_..b, neg_integer()) when b < 0 do
    [neg_integer()]
  end

  # positive integers with integers and ranges.  Note that positive integer
  # will always be greater than these ranges.
  def type_merge(i, pos_integer()) when is_integer(i) and i > 0 do
    [pos_integer()]
  end
  def type_merge(a.._, pos_integer()) when a > 0 do
    [pos_integer()]
  end
  def type_merge(0.._, pos_integer()) do
    [0, pos_integer()]
  end
  def type_merge(a..b, pos_integer()) when b > 0 do
    [a..0, pos_integer()]
  end

  # atom literals
  def type_merge(atom, atom()) when is_atom(atom) do
    [atom()]
  end

  # tuples
  alias Type.Tuple
  def type_merge(%Tuple{}, tuple()) do
    [tuple()]
  end
  def type_merge(lhs = %Tuple{}, rhs = %Tuple{}) do
    strict = lhs.fixed and rhs.fixed
    if merged_elements = Tuple.merge(rhs.elements, lhs.elements, strict) do
      [%Tuple{elements: merged_elements, fixed: strict}]
    else
      :nomerge
    end
  end

  # lists
  alias Type.List
  # matching types with different finals.
  def type_merge(%List{type: type, final: fl},
                  %List{type: type, final: fr}) do

    [%List{type: type, final: Type.union(fl, fr)}]
  end
  def type_merge(%List{type: t1, final: f}, %List{type: t2, final: f}) do
    # check if the types are mergable
    case Type.intersect(t1, t2) do
      ^t1 ->
        [%List{type: t2, final: f}]
      ^t2 ->
        [%List{type: t1, final: f}]
      _ ->
        :nomerge
    end
  end

  # maps
  alias Type.Map
  def type_merge(left = %Map{}, right = %Map{}) do
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

  # bitstrings and binaries
  alias Type.Bitstring
  def type_merge(_, %Bitstring{unit: 0}), do: :nomerge
  def type_merge(%Bitstring{size: 0, unit: lh}, %Bitstring{size: rh, unit: rh}) do
    [%Bitstring{size: 0, unit: lh}, %Bitstring{size: 0, unit: rh}]
  end
  def type_merge(left = %Bitstring{unit: 0}, right = %Bitstring{}) do
    if rem(right.size - left.size, right.unit) == 0 do
      [right]
    else
      :nomerge
    end
  end
  def type_merge(left = %Bitstring{unit: lhu}, right = %Bitstring{unit: rhu})
      when rem(lhu, rhu) == 0 do
    if rem(left.size - right.size, rhu) == 0 do
      [right]
    else
      :nomerge
    end
  end

  # any
  def type_merge(_, any()) do
    [any()]
  end
  def type_merge(_, _), do: :nomerge

  defp count_diffs_merge(zip) do
    Enum.map_reduce(zip, 0, fn
      {type, type}, total when total < 2 ->
        {type, total}
      {left_t, right_t}, total when total < 2 ->
        {Type.union(left_t, right_t), total + 1}
      _, total ->
        {nil, total}
    end)
  end
end
