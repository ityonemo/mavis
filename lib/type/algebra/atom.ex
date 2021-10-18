defimpl Type.Algebra, for: Atom do

  require Type
  alias Type.Helpers

  require Helpers
  Helpers.typegroup_fun()
  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)
  Helpers.algebra_intersection_fun(__MODULE__, :intersection_internal)
  Helpers.algebra_subtype_fun(__MODULE__, :subtype_internal)

  def compare_internal(_latom, Type.atom()), do: :lt
  def compare_internal(latom, ratom) when latom < ratom, do: :lt
  def compare_internal(latom, ratom) when latom > ratom, do: :gt

  def intersection_internal(atom, Type.atom()), do: atom
  def intersection_internal(_, _), do: Type.none()

  def subtype_internal(_, Type.atom()), do: true
  def subtype_internal(_, _), do: false

#  use Type.Helpers
#
#  alias Type.Message
#
#  group_compare do
#    def group_compare(_, atom()), do: :lt
#    def group_compare(left, right),       do: (if left >= right, do: :gt, else: :lt)
#  end
#
#  usable_as do
#    def usable_as(_, atom(), _), do: :ok
#    def usable_as(atom, node_type(), meta) do
#      if Type.Algebra.Type.valid_node?(atom) do
#        :ok
#      else
#        {:error, Message.make(atom, node_type(), meta)}
#      end
#    end
#    def usable_as(atom, module(), meta) do
#      if Type.Algebra.Type.valid_module?(atom) do
#        :ok
#      else
#        {:maybe, [Message.make(atom, module(), meta)]}
#      end
#    end
#  end
#
#  intersection do
#    def intersection(atom, atom()), do: atom
#    def intersection(atom, node_type()) do
#      if Type.Algebra.Type.valid_node?(atom), do: atom, else: none()
#    end
#    def intersection(atom, module()) do
#      if Type.Algebra.Type.valid_module?(atom), do: atom, else: none()
#    end
#  end
#
#  subtract do
#  end
#
#  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end
