defimpl Type.Algebra, for: Integer do

  alias Type.Helpers
  require Helpers

  Helpers.typegroup_fun()
  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)

  import Type, only: :macros
  def compare_internal(a, neg_integer()) when a >= 0, do: :gt
  def compare_internal(a, _..rg) when a > rg, do: :gt
  def compare_internal(a, b) when a > b, do: :gt
  def compare_internal(_, _), do: :lt

#  use Type.Helpers
#
#  group_compare do
#    def group_compare(left, neg_integer()),       do: (if left >= 0, do: :gt, else: :lt)
#    def group_compare(_, pos_integer()),          do: :lt
#    def group_compare(left, _..last),                     do: (if left > last, do: :gt, else: :lt)
#    def group_compare(left, right) when is_integer(right) do
#      cond do
#        left > right -> :gt
#        left < right -> :lt
#        true -> :eq
#      end
#    end
#    def group_compare(left, %Type.Union{of: ints}) do
#      group_compare(left, List.last(ints))
#    end
#  end
#
#  usable_as do
#    def usable_as(i, a..b, _) when a <= i and i <= b,           do: :ok
#    def usable_as(i, pos_integer(), _) when i > 0,      do: :ok
#    def usable_as(i, neg_integer(), _) when i < 0,      do: :ok
#  end
#
#  intersection do
#    def intersection(i, a..b) when a <= i and i <= b, do: i
#    def intersection(i, neg_integer()) when i < 0, do: i
#    def intersection(i, pos_integer()) when i > 0, do: i
#  end
#
#  subtract do
#  end
#
#  subtype :usable_as
end
