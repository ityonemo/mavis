defimpl Type.Algebra, for: Integer do

  alias Type.Helpers
  alias Type.Message

  require Helpers

  Helpers.typegroup_fun()
  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)

  import Type, only: :macros
  def compare_internal(a, neg_integer()) when a >= 0, do: :gt
  def compare_internal(a, _..rg) when a > rg, do: :gt
  def compare_internal(a, b) when a > b, do: :gt
  def compare_internal(_, _), do: :lt

  Helpers.algebra_merge_fun(__MODULE__, :merge_internal)

  def merge_internal(a, b) when b === a - 1, do: {:merge, [b..a]}
  def merge_internal(a, b..c) when c == a - 1, do: {:merge, [b..a]}
  def merge_internal(_, _), do: :nomerge

  Helpers.algebra_intersection_fun(__MODULE__, :intersect_internal)

  def intersect_internal(i, a..b) when i in a..b, do: i
  def intersect_internal(i, neg_integer()) when i < 0, do: i
  def intersect_internal(i, pos_integer()) when i > 0, do: i
  def intersect_internal(_, _), do: %Type{name: :none}

  Helpers.algebra_subtype_fun(__MODULE__, :subtype_internal)

  def subtype_internal(i, a..b) when i in a..b, do: true
  def subtype_internal(i, neg_integer()) when i < 0, do: true
  def subtype_internal(i, pos_integer()) when i > 0, do: true
  def subtype_internal(_, _), do: false

  Helpers.algebra_usable_as_fun(__MODULE__, :usable_as_internal)

  def usable_as_internal(a, b..c, _) when a in b..c, do: :ok
  def usable_as_internal(a, pos_integer(), _) when a > 0, do: :ok
  def usable_as_internal(a, neg_integer(), _) when a < 0, do: :ok
  def usable_as_internal(challenge, target, meta) do
    {:error, Message.make(challenge, target, meta)}
  end

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
#
#  subtract do
#  end
#
#  subtype :usable_as
end
