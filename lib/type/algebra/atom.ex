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
    atom
    |> Atom.to_string
    |> String.match?(~r/^[[:alnum:]]+@[[:alnum:]]+$/)
  end

  Helpers.algebra_subtype_fun(__MODULE__, :subtype_internal)
  def subtype_internal(_, atom()), do: true
  def subtype_internal(maybe_module, module()) do
    # this might be dangerous?
    function_exported?(maybe_module, :module_info, 0)
  end
  def subtype_internal(maybe_node, type(node())) do
    valid_node?(maybe_node)
  end
  def subtype_internal(_, _), do: false

  Helpers.algebra_usable_as_fun(__MODULE__, :usable_as_internal)

  def usable_as_internal(_, atom(), _), do: :ok
  def usable_as_internal(atom, type(node()), meta) do
    if valid_node?(atom) do
      :ok
    else
      {:error, Message.make(atom, type(node()), meta)}
    end
  end
  # TODO: log the usable_as content as a post-check
  def usable_as_internal(maybe_module, module(), meta) do
    if function_exported?(maybe_module, :module_info, 0) do
      :ok
    else
      # be ready to post-check resolve this.
      {:maybe, [Message.make(maybe_module, module(), meta)]}
    end
  end
  def usable_as_internal(challenge, target, meta) do
    {:error, Message.make(challenge, target, meta)}
  end
end
