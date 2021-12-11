defimpl Type.Algebra, for: List do

  alias Type.Helpers
  alias Type.Message

  require Helpers

  import Type, only: :macros

  Helpers.typegroup_fun()

  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)
  def compare_internal(_, %Type.List{}), do: :lt
  def compare_internal(a, b) when a < b, do: :lt
  def compare_internal(a, b) when a > b, do: :gt

  Helpers.algebra_merge_fun(__MODULE__, :merge_internal)
  def merge_internal(_, _), do: :nomerge

  @iolist %Type.Union{of: [
    %Type.List{
      type: %Type.Union{of: [binary(), iolist(), byte()]},
      final: %Type.Union{of: [binary(), []]}}, []]}

  Helpers.algebra_intersection_fun(__MODULE__, :intersect_internal)
  def intersect_internal(left, iolist()) do
    Type.intersect(@iolist, left)
  end
  def intersect_internal(left, right) when is_list(right) do
    intersect_lists(left, right, [])
  end
  # improper final position stuff
  def intersect_internal(_, _), do: none()

  defp intersect_lists([lhead | ltail], [rhead | rtail], so_far) do
    case Type.intersect(lhead, rhead) do
      none() -> none()
      type -> intersect_lists(ltail, rtail, [type | so_far])
    end
  end

  defp intersect_lists([], [], so_far), do: Enum.reverse(so_far)

  defp intersect_lists(left, right, _) when is_list(left) or is_list(right), do: none()
  defp intersect_lists(left, right, so_far) do
    case Type.intersect(left, right) do
      none() -> none()
      type -> reverse_prepend(so_far, type)
    end
  end

  defp reverse_prepend([], list), do: list
  defp reverse_prepend([a | b], list), do: reverse_prepend(b, [a | list])

  Helpers.algebra_subtype_fun(__MODULE__, :subtype_internal)
  def subtype_internal(_, _), do: false

  Helpers.algebra_usable_as_fun(__MODULE__, :usable_as_internal)

  def usable_as_internal([], iolist(), _), do: :ok
  def usable_as_internal(list, iolist(), meta) do
    case usable_as_iolist(list) do
      :ok -> :ok
      :error -> {:error, Message.make(list, iolist(), meta)}
    end
  end
  def usable_as_internal([], type = %Type.List{}, meta) do
    {:error, Message.make([], type, meta)}
  end
  def usable_as_internal(list, type = %Type.List{}, meta) do
    case usable_literal(list, type) do
      :ok -> :ok
      :maybe -> {:maybe, [Message.make(list, type, meta)]}
      :error -> {:error, Message.make(list, type, meta)}
    end
  end
  def usable_as_internal(challenge, target, meta) do
    {:error, Message.make(challenge, target, meta)}
  end

  defp usable_as_iolist([head | rest]) when not is_integer(rest) do
    case usable_as_iolist(head) do
      :ok -> usable_as_iolist(rest)
      error -> error
    end
  end
  defp usable_as_iolist(binary) when is_binary(binary), do: :ok
  defp usable_as_iolist(integer) when is_integer(integer) and
      0 < integer and integer < 0x10FFF do
    :ok
  end
  defp usable_as_iolist(_) do
    :error
  end

  defp usable_literal(list, type), do: usable_literal(list, type, :ok)
  defp usable_literal([head | rest], list_type = %{type: type}, so_far) do
    case Type.usable_as(head, type, []) do
      :ok -> usable_literal(rest, list_type, so_far)
      maybe = {:maybe, _} -> usable_literal(rest, list_type, maybe)
      {:error, _} -> :error
    end
  end
  defp usable_literal(final_element, %{final: final}, so_far) do
    case {Type.usable_as(final_element, final, []), so_far} do
      {:ok, :ok} -> :ok
      {:ok, {:maybe, _}} -> :maybe
      {{:maybe, _}, _} -> :maybe
      {{:error, _}, _} -> :error
    end
  end
end
