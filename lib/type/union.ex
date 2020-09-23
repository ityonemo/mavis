defmodule Type.Union do
  defstruct [of: []]
  @type t :: %__MODULE__{of: [Type.t]}

  import Type, only: [builtin: 1]

  def of(left, right) do
    Enum.into([left, right], %__MODULE__{})
  end

  # for now.  TODO: we need more sophisticated checking on this.
  def collapse(%__MODULE__{of: types}) do
    types
    |> Enum.flat_map(fn
      union = %__MODULE__{} -> collapse(union).of
      other_type -> [other_type]
    end)
    |> Enum.sort(&Type.order/2)
    |> Enum.reduce([], &subsume/2)
    |> case do
      [] -> %Type{name: :none}
      [one] -> one
      list -> %__MODULE__{of: list}
    end
  end

  require Type
  alias Type.{Function, List}

  # anything that is exactly the same must come back the same.
  def subsume(any, [any | rest]) do
    [any | rest]
  end
  def subsume(builtin(:neg_integer), [a..b | rest])
      when a < 0 and b >= 0 do
    [builtin(:neg_integer), 0..b | rest]
  end
  def subsume(a, [b | rest]) when b == a + 1 do
    [a..b | rest]
  end
  def subsume(a, [b..c | rest]) when b == a + 1 do
    [a..c | rest]
  end
  def subsume(a..b, [c | rest]) when c <= b + 1 do
    [a..c | rest]
  end
  def subsume(a..b, [c..d | rest]) when c <= b + 1 do
    [a..max(b, d) | rest]
  end
  def subsume(a..b, [builtin(:non_neg_integer) | rest]) when b >= -1 do
    [a..-1, builtin(:non_neg_integer) | rest]
  end
  def subsume(builtin(:neg_integer), [builtin(:non_neg_integer) | rest]) do
    [builtin(:integer) | rest]
  end
  def subsume(0, [builtin(:pos_integer) | rest]) do
    [builtin(:non_neg_integer) | rest]
  end
  def subsume(0.._, [builtin(:pos_integer) | rest]) do
    [builtin(:non_neg_integer) | rest]
  end
  def subsume(-1.._, [builtin(:pos_integer) | rest]) do
    [-1, builtin(:non_neg_integer) | rest]
  end
  def subsume(a.._, [builtin(:pos_integer) | rest]) when a < -1 do
    [a..-1, builtin(:non_neg_integer) | rest]
  end
  def subsume(a..b, [builtin(:pos_integer) | rest]) when a < 0 and b >= 0 do
    [a..-1, builtin(:non_neg_integer) | rest]
  end
  def subsume(l1 = %List{final: f, nonempty: n}, [l2 = %List{final: f, nonempty: n} | rest]) do
    merged_type = Enum.into([l1.type, l2.type], %__MODULE__{})
    merged = %List{type: merged_type, final: f, nonempty: n}
    [merged | rest]
  end
  def subsume(l1 = %List{type: t, nonempty: n}, [l2 = %List{type: t, nonempty: n} | rest]) do
    merged_final = Enum.into([l1.final, l2.final], %__MODULE__{})
    merged = %List{type: t, final: merged_final, nonempty: n}
    [merged | rest]
  end
  def subsume(f1 = %Function{}, [f2 = %Function{} | rest]) do
    subsume_function(f1, f2, rest)
  end
  def subsume(prev, [next | rest]) do
    if Type.coercion(next, prev) == :type_ok do
      subsume(prev, rest)
    else
      [prev, next | rest]
    end
  end
  def subsume(next, []), do: [next]

  # :any function rules
  def subsume_function(
    f1 = %{params: :any, return: r1},
    f2 = %{params: :any, return: r2}, rest) do
    if Type.coercion(r2, r1) == :type_ok do
      [f1 | rest]
    else
      [f1, f2 | rest]
    end
  end
  def subsume_function(f1 = %{params: :any}, f2 = %{params: _}, rest) do
    if Type.coercion(f2.return, f1.return) == :type_ok do
      [f1 | rest]
    else
      [f1, f2 | rest]
    end
  end
  # rules for functions where the params are lists
  def subsume_function(f1 = %{params: p1}, f2 = %{params: p2}, rest) when
    length(p1) != length(p2) do
    # if they don't have the same number of parameters, then the functions
    # live in orthogonal type spaces.
      [f1, f2 | rest]
  end
  def subsume_function(f1, f2, rest) do
    subtype = [f1.return | f1.params]
    |> Enum.zip([f2.return | f2.params])
    |> Enum.all?(fn {t1, t2} -> Type.coercion(t2, t1) == :type_ok end)

    if subtype do
      [f1 | rest]
    else
      [f1, f2 | rest]
    end
  end

  defimpl Type.Typed do
    import Type, only: [builtin: 1]

    def order(_union, builtin(:none)), do: true
    def order(union, type) do
      union.of
      |> Elixir.List.last
      |> Type.order(type)
    end

    def typegroup(union) do
      union.of
      |> Elixir.List.last
      |> Type.Typed.typegroup
    end
  end

  defimpl Collectable do
    alias Type.Union

    def into(original) do
      collector_fun = fn
        # starting with an empty union results in
        list, {:cont, elem} -> [elem | list]
        list, :done -> Union.collapse(%Union{of: list})
        _set, :halt -> :ok
      end

      {original.of, collector_fun}
    end
  end
end
