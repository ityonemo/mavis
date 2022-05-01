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

  Helpers.algebra_subtype_fun(__MODULE__, :subtype_internal)
  def subtype_internal(_, float()), do: true
  def subtype_internal(_, _), do: false
end
