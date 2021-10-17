defimpl Type.Algebra, for: Atom do

  alias Type.Helpers

  require Helpers
  Helpers.typegroup_fun()
  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)

  def compare_internal(_, _), do: raise "unimplemented"



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
