defmodule Type.Union do
  defstruct [of: []]
  @type t :: %__MODULE__{of: [Type.t]}

  import Type, only: :macros

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
  def subsume(prev, [next | rest]) do
    if subsumes(prev, next) do
      subsume(prev, rest)
    else
      [prev, next | rest]
    end
  end
  def subsume(next, []), do: [next]

  alias Type.Tuple

  # note, as a precondition, the two values must already be sorted.
  defp subsumes(any, any),                                             do: true
  defp subsumes(builtin(:any), _any),                                  do: true
  defp subsumes(builtin(:integer), builtin(:neg_integer)),             do: true
  defp subsumes(builtin(:integer), n) when is_integer(n),              do: true
  defp subsumes(builtin(:integer), builtin(:non_neg_integer)),         do: true
  defp subsumes(builtin(:integer), builtin(:pos_integer)),             do: true
  defp subsumes(builtin(:integer), %Range{}),                          do: true
  defp subsumes(builtin(:neg_integer), n) when Type.is_neg_integer(n), do: true
  defp subsumes(builtin(:neg_integer), a..b) when a < 0 and b < 0,     do: true
  defp subsumes(builtin(:non_neg_integer), n) when is_integer(n),      do: true
  defp subsumes(builtin(:non_neg_integer), _.._),                      do: true
  defp subsumes(builtin(:non_neg_integer), builtin(:pos_integer)),     do: true
  defp subsumes(builtin(:pos_integer), n) when is_integer(n),          do: true
  defp subsumes(builtin(:pos_integer), _.._),                          do: true
  defp subsumes(range = %Range{}, n) when is_integer(n),               do: n in range
  defp subsumes(builtin(:atom), atom) when is_atom(atom),              do: true
  defp subsumes(%Tuple{elements: :any}, %Tuple{}),                     do: true
  defp subsumes(%Tuple{elements: e1}, %Tuple{elements: e2})
    when length(e1) == length(e2) do
    e1
    |> Enum.zip(e2)
    |> Enum.all?(fn {left, right} -> subsumes(left, right) end)
  end
  defp subsumes(_, _),                                                 do: false

  defimpl Type.Typed do
    import Type, only: :macros

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(_, _), do: :type_error
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
