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

  def intersect_internal(atom, Type.atom()), do: atom
  def intersect_internal(atom, Type.type(node())) do
    if valid_node?(atom), do: atom, else: Type.none()
  end
  def intersect_internal(a, b) do
    Type.none()
  end

  def valid_node?(atom) do
    node_parts = atom
    |> Atom.to_string
    |> String.split("@")
    match?([<<_::8>> <> _, <<_::8>> <> _], node_parts)
  end

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
#    def usable_as(atom, type(node()), meta) do
#      if Type.Algebra.Type.valid_node?(atom) do
#        :ok
#      else
#        {:error, Message.make(atom, type(node()), meta)}
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
#    def intersect(atom, atom()), do: atom
#    def intersect(atom, type(node())) do
#      if Type.Algebra.Type.valid_node?(atom), do: atom, else: none()
#    end
#    def intersect(atom, module()) do
#      if Type.Algebra.Type.valid_module?(atom), do: atom, else: none()
#    end
#  end
#
#  subtract do
#  end
#
#  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end
