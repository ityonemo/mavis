defimpl Type.Algebra, for: Range do
  alias Type.Helpers
  require Helpers

  import Type, only: :macros

  Helpers.typegroup_fun

  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)

  def compare_internal(_, pos_integer()),                      do: :lt
  def compare_internal(_..last, neg_integer()),                do: (if last >= 0, do: :gt, else: :lt)
  def compare_internal(first1..last, first2..last),            do: (if first1 < first2, do: :gt, else: :lt)
  def compare_internal(_..last1, _..last2),                    do: (if last1 > last2, do: :gt, else: :lt)
  def compare_internal(_..last, right) when is_integer(right), do: (if last >= right, do: :gt, else: :lt)
  def compare_internal(first..last, %Type.Union{of: [init | types]}) do
    case List.last(types) do
      _..b when b < last -> :gt
      _.._ ->
        Type.compare(init, first)
      i when i < last -> :gt
      i when is_integer(i) ->
        Type.compare(init, first)
      _ -> :lt
    end
  end

  Helpers.algebra_merge_fun(__MODULE__, :merge_internal)

  def merge_internal(a..b, c) when is_integer(c) do
    cond do
      c == a - 1 -> {:merge, [c..b]}
      c == b + 1 -> {:merge, [a..c]}
      a <= c and c <= b -> {:merge, [a..b]}
      true -> :nomerge
    end
  end
  def merge_internal(a..b, c..d) do
    cond do
      b == c - 1 -> {:merge, [a..d]}
      a == d + 1 -> {:merge, [c..b]}
      b < c -> :nomerge
      d < a -> :nomerge
      true -> case {a <= c, a >= c, b <= d, b >= d} do
        {true, _, _, true} -> {:merge, [a..b]}
        {_, true, true, _} -> {:merge, [c..d]}
        {true, _, true, _} -> {:merge, [a..d]}
        {_, true, _, true} -> {:merge, [c..b]}
      end
    end
  end
  def merge_internal(0.._, pos_integer()), do: {:merge, [pos_integer(), 0]}
  def merge_internal(a..b, pos_integer()) when b > 0 do
    if a > 0, do: {:merge, [pos_integer()]}, else: {:merge, [pos_integer(), a..0]}
  end
  def merge_internal(_..0, neg_integer()), do: {:merge, [0, neg_integer()]}
  def merge_internal(a..b, neg_integer()) when a < 0 do
    if b < 0, do: {:merge, [neg_integer()]}, else: {:merge, [0..b, neg_integer()]}
  end

  def merge_internal(_, _), do: :nomerge

  Helpers.algebra_intersection_fun(__MODULE__, :intersect_internal)

  def intersect_internal(a..b, i) when a <= i and i <= b, do: i
  def intersect_internal(a.._, _..a), do: a
  def intersect_internal(_..a, a.._), do: a
  def intersect_internal(-1.._, neg_integer()), do: -1
  def intersect_internal(a.._, neg_integer()) when a < 0, do: a..-1
  def intersect_internal(a..b, c..d) do
    case {a >= c, a > d, b < c, b <= d} do
      {_,     x, y, _} when x or y -> none()
      {false, _, _, true}  -> c..b
      {true,  _, _, true}  -> a..b
      {true,  _, _, false} -> a..d
      {false, _, _, false} -> c..d
    end
  end
  def intersect_internal(_, _), do: Type.none()

#
#  usable_as do
#    def usable_as(a.._, pos_integer(), _) when a > 0,      do: :ok
#    def usable_as(_..a, neg_integer(), _) when a < 0,      do: :ok
#    def usable_as(a..b, pos_integer(), meta) when b > 0 do
#      {:maybe, [Type.Message.make(a..b, pos_integer(), meta)]}
#    end
#    def usable_as(a..b, neg_integer(), meta) when a < 0 do
#      {:maybe, [Type.Message.make(a..b, neg_integer(), meta)]}
#    end
#    def usable_as(a..b, target, meta)
#        when is_integer(target) and a <= target and target <= b do
#      {:maybe, [Type.Message.make(a..b, target, meta)]}
#    end
#    def usable_as(a..b, c..d, meta) do
#      cond do
#        a >= c and b <= d -> :ok
#        a > d or b < c -> {:error, Type.Message.make(a..b, c..d, meta)}
#        true ->
#          {:maybe, [Type.Message.make(a..b, c..d, meta)]}
#      end
#    end
#    # strange stitched ranges
#    def usable_as(range, union = %Type.Union{of: list}, meta) do
#      # take the intersections and make sure they reassemble to the
#      # range.
#      list
#      |> Enum.map(&Type.intersect(&1, range))
#      |> Type.union
#      |> case do
#        none() -> {:error, Type.Message.make(range, union, meta)}
#        ^range -> :ok
#        _ -> {:maybe, [Type.Message.make(range, union, meta)]}
#      end
#    end
#  end
#
#  subtract do
#    # basic types
#    def subtract(_..b, neg_integer()) when b < 0, do: none()
#    def subtract(a..b, neg_integer()) when a >= 0, do: a..b
#    def subtract(_..b, neg_integer()), do: rangeresolve(0, b)
#    def subtract(a.._, pos_integer()) when a > 0, do: none()
#    def subtract(a..b, pos_integer()) when b <= 0, do: a..b
#    def subtract(a.._, pos_integer()), do: rangeresolve(a, 0)
#    # integers
#    def subtract(a..b, c) when is_integer(c) and (c < a or c > b), do: a..b
#    def subtract(a..b, a), do: rangeresolve(a + 1, b)
#    def subtract(a..b, b), do: rangeresolve(a, b - 1)
#    def subtract(a..b, c) when is_integer(c) do
#      Type.union(rangeresolve(a, c - 1), rangeresolve(c + 1, b))
#    end
#    def subtract(a..b, c..d) do
#      case {a >= c, a > d, b < c, b <= d} do
#        {_,     x, y, _} when x or y -> a..b
#        {false, _, _, true}  -> rangeresolve(a, c - 1)
#        {true,  _, _, true}  -> none()
#        {true,  _, _, false} -> rangeresolve(d + 1, b)
#        {false, _, _, false} -> Type.union(rangeresolve(a, c - 1), rangeresolve(d + 1, b))
#      end
#    end
#    def subtract(a..b, _), do: a..b
#  end
#
#  defp rangeresolve(a, a), do: a
#  defp rangeresolve(a, b) when a < b, do: a..b
#  defp rangeresolve(_, _), do: none()
#
#  subtype :usable_as
end
