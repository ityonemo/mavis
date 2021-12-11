defimpl Type.Algebra, for: Atom do
  
  alias Type.Helpers
  alias Type.Message

  import Type, only: :macros

  require Helpers
  Helpers.typegroup_fun()

  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)
  def compare_internal(_latom, atom()), do: :lt
  def compare_internal(latom, ratom) when latom < ratom, do: :lt
  def compare_internal(latom, ratom) when latom > ratom, do: :gt

  Helpers.algebra_merge_fun(__MODULE__, :merge_internal)
  def merge_internal(_, _), do: :nomerge

  Helpers.algebra_intersection_fun(__MODULE__, :intersect_internal)
  def intersect_internal(atom, atom()), do: atom
  def intersect_internal(atom, type(node())) do
    if valid_node?(atom), do: atom, else: none()
  end
  def intersect_internal(_, _), do: none()

  def valid_node?(atom) do
    node_parts = atom
    |> Atom.to_string
    |> String.split("@")
    match?([<<_::8>> <> _, <<_::8>> <> _], node_parts)
  end

  Helpers.algebra_subtype_fun(__MODULE__, :subtype_internal)
  def subtype_internal(_, atom()), do: true
  def subtype_internal(_, _), do: false

  Helpers.algebra_usable_as_fun(__MODULE__, :usable_as_internal)

  def usable_as_internal(_, atom(), _), do: :ok
  def usable_as_internal(atom, type(node()), meta) do
    if Type.Algebra.Atom.valid_node?(atom) do
      :ok
    else
      {:error, Message.make(atom, type(node()), meta)}
    end
  end
  # TODO: log the usable_as content as a post-check
  def usable_as_internal(_, module(), _), do: :ok
  def usable_as_internal(challenge, target, meta) do
    {:error, Message.make(challenge, target, meta)}
  end

#  subtract do
#  end
#
#  def subtype?(a, b), do: usable_as(a, b, []) == :ok
end
