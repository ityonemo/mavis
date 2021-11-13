defimpl Type.Algebra, for: Float do

  require Type

  alias Type.Helpers
  require Helpers

  Helpers.typegroup_fun()
  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)
  Helpers.algebra_intersection_fun(__MODULE__, :intersection_internal)

  def compare_internal(a, b) when a < b, do: :lt
  def compare_internal(a, b) when a > b, do: :gt

  def intersect_internal(_, _), do: Type.none()

#  use Type.Helpers
#
#  group_compare do
#    def group_compare(_, float()), do: :lt
#    def group_compare(rvalue, lvalue)
#      when rvalue < lvalue, do: :lt
#    def group_compare(rvalue, lvalue)
#      when rvalue == lvalue, do: :eq
#    def group_compare(rvalue, lvalue)
#      when rvalue > lvalue, do: :gt
#    def group_compare(_, _), do: :lt
#  end
#
#  ###########################################################################
#  ## SUBTYPE
#
#  subtype :usable_as
#
#  ###########################################################################
#  ## USABLE_AS
#
#  usable_as do
#    def usable_as(_value, float(), _meta), do: :ok
#  end
#
#  intersection do
#    def intersect(value, float()), do: value
#  end
#
#  subtract do
#  end
#
#  def normalize(_float), do: float()
end
