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
  def type_merge(%Tuple{elements: {:min, m}}, %Tuple{elements: {:min, n}}) do
    [tuple({...(min: min(m, n))})]
  end
  def type_merge(%Tuple{elements: els}, %Tuple{elements: {:min, n}}) do
    if length(els) >= n do
      [tuple({...(min: n)})]
    else
      :nomerge
    end
  end
  def type_merge(lhs = %Tuple{}, rhs = %Tuple{}) do
    if merged_elements = Tuple.merge(rhs.elements, lhs.elements) do
      [%Tuple{elements: merged_elements}]
    else
      :nomerge
    end
  end

  # lists
  alias Type.List
  # matching finals
  def type_merge(%List{type: tl, nonempty: nl, final: final},
                  %List{type: tr, nonempty: nr, final: final}) do
    [%List{type: Type.union(tl, tr), nonempty: nl and nr, final: final}]
  end
  # matching types
  def type_merge(%List{type: type, nonempty: nl, final: fl},
                  %List{type: type, nonempty: nr, final: fr}) do

    [%List{type: type, nonempty: nl and nr, final: Type.union(fl, fr)}]
  end
  def type_merge([], %List{type: type, final: final}) do
    # technically this shouldn't be necessary since all nonempty lists must
    # be able to have final []
    [%List{type: type, final: Type.union(final, [])}]
  end
  def type_merge(%List{type: type, final: final, nonempty: true}, []) do
    [%List{type: type, final: Type.union(final, []), nonempty: false}]
  end
  def type_merge(l1 = %List{}, l2 = %List{}) do
    if merge = Tuple.merge([l1.type, l1.final], [l2.type, l2.final]) do
      [type, final] = merge
      [%List{type: type, final: final, nonempty: l1.nonempty and l2.nonempty}]
    else
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

  # functions
  alias Type.Function
  def type_merge(%Function{params: p, return: left},
                  %Function{params: p, return: right}) do
    [%Function{params: p, return: Type.union(left, right)}]
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
  def type_merge(%Type{module: String, name: :t}, remote(String.t)) do
    [remote(String.t)]
  end
  def type_merge(%Type{module: String, name: :t, params: [left]},
                  %Type{module: String, name: :t, params: [right]}) do
    lengths = Type.union(left, right)
    [remote(String.t(lengths))]
  end
  def type_merge(%Type{module: String, name: :t, params: []},
                  %Bitstring{size: 0, unit: unit})
                  when unit in [1, 2, 4, 8] do
    [%Bitstring{unit: unit}]
  end
  def type_merge(%Type{module: String, name: :t, params: [bytes]},
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
  def type_merge(_, any()) do
    [any()]
  end
  def type_merge(_, _), do: :nomerge
end
