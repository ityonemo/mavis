defimpl Type.Algebra, for: Range do
#  import Type, only: :macros
#
#  use Type.Helpers
#
#  group_compare do
#    def group_compare(_, pos_integer()),              do: :lt
#    def group_compare(_..last, neg_integer()),        do: (if last >= 0, do: :gt, else: :lt)
#    def group_compare(first1..last, first2..last),            do: (if first1 < first2, do: :gt, else: :lt)
#    def group_compare(_..last1, _..last2),                    do: (if last1 > last2, do: :gt, else: :lt)
#    def group_compare(_..last, right) when is_integer(right), do: (if last >= right, do: :gt, else: :lt)
#    def group_compare(first..last, %Type.Union{of: [init | types]}) do
#      case List.last(types) do
#        _..b when b < last -> :gt
#        _..b ->
#          # the range is bigger if it's bigger than the biggest union
#          raise "foo bar"
#          Type.compare(init, first) && (last >= b)
#        i when i < last -> :gt
#        i when is_integer(i) ->
#          Type.compare(init, first) && (last >= i)
#        _ -> :lt
#      end
#    end
#  end
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
#      |> Enum.map(&Type.intersection(&1, range))
#      |> Type.union
#      |> case do
#        none() -> {:error, Type.Message.make(range, union, meta)}
#        ^range -> :ok
#        _ -> {:maybe, [Type.Message.make(range, union, meta)]}
#      end
#    end
#  end
#
#  intersection do
#    def intersection(a..b, i) when a <= i and i <= b, do: i
#    def intersection(a.._, _..a), do: a
#    def intersection(_..a, a.._), do: a
#    def intersection(a..b, c..d) do
#      case {a >= c, a > d, b < c, b <= d} do
#        {_,     x, y, _} when x or y -> none()
#        {false, _, _, true}  -> c..b
#        {true,  _, _, true}  -> a..b
#        {true,  _, _, false} -> a..d
#        {false, _, _, false} -> c..d
#      end
#    end
#    def intersection(a..b,  neg_integer()) when b < 0, do: a..b
#    def intersection(-1.._, neg_integer()), do: -1
#    def intersection(a.._,  neg_integer()) when a < 0, do: a..-1
#    def intersection(a..b,  pos_integer()) when a > 0, do: a..b
#    def intersection(_..1,  pos_integer()), do: 1
#    def intersection(_..a,  pos_integer()) when a > 1, do: 1..a
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
