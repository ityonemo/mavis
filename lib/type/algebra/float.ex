defimpl Type.Algebra, for: Float do

  alias Type.Helpers
  alias Type.Message
  require Helpers

  import Type, only: :macros

  Helpers.typegroup_fun()

  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)
  def compare_internal(a, b) when a < b, do: :lt
  def compare_internal(a, b) when a > b, do: :gt

  Helpers.algebra_merge_fun(__MODULE__, :merge_internal)
  def merge_internal(_, _), do: :nomerge

  Helpers.algebra_intersection_fun(__MODULE__, :intersect_internal)
  def intersect_internal(_, _), do: %Type{name: :none}

  Helpers.algebra_usable_as_fun(__MODULE__, :usable_as_internal)

  def usable_as_internal(a, float(), _), do: :ok
  def usable_as_internal(challenge, target, meta) do
    {:error, Message.make(challenge, target, meta)}
  end


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
