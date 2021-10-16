defimpl Type.Algebra, for: Float do
  import Type, only: :macros
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
#    def intersection(value, float()), do: value
#  end
#
#  subtract do
#  end
#
#  def normalize(_float), do: float()
end
