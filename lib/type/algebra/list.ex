defimpl Type.Algebra, for: List do

  require Type

  alias Type.Helpers
  require Helpers

  Helpers.typegroup_fun()
  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)
  Helpers.algebra_intersection_fun(__MODULE__, :intersection_internal)

  def compare_internal(_, %Type.List{}), do: :lt
  def compare_internal(a, b) when a < b, do: :lt
  def compare_internal(a, b) when a > b, do: :gt

  def intersection_internal(a, b), do: Type.none()

#  use Type.Helpers
#
#  alias Type.Message
#
#  group_compare do
#    def group_compare(_, %Type.List{}), do: :lt
#    def group_compare(left, right) when is_list(right) do
#      cond do
#        left < right -> :lt
#        left == right -> :eq
#        true -> :gt
#      end
#    end
#  end
#
#  usable_as do
#    def usable_as([], iolist(), _), do: :ok
#    def usable_as(list, iolist(), meta) when is_list(list) do
#      case usable_as_iolist(list) do
#        :ok -> :ok
#        :error -> {:error, Message.make(list, iolist(), meta)}
#      end
#    end
#    def usable_as([], type = %Type.List{}, meta) do
#      {:error, Message.make([], type, meta)}
#    end
#    def usable_as(list, type = %Type.List{}, meta) when is_list(list) do
#      case Type.List.usable_literal(type, list) do
#        :ok -> :ok
#        {:maybe, _} -> {:maybe, [Message.make(list, type, meta)]}
#        {:error, _} -> {:error, Message.make(list, type, meta)}
#      end
#    end
#  end
#
#  defp usable_as_iolist([head | rest]) when not is_integer(rest) do
#    case usable_as_iolist(head) do
#      :ok -> usable_as_iolist(rest)
#      error -> error
#    end
#  end
#  defp usable_as_iolist(binary) when is_binary(binary), do: :ok
#  defp usable_as_iolist(integer) when is_integer(integer) and
#      0 < integer and integer < 0x10FFF do
#    :ok
#  end
#  defp usable_as_iolist(_) do
#    :error
#  end
#
#  intersection do
#    def intersection([], %Type.List{}), do: none()
#    def intersection([], iolist()), do: Type.Iolist.intersection_with([])
#    def intersection([], _), do: none()
#    def intersection(rvalue, iolist()) do
#      if Type.subtype?(rvalue, iolist()), do: rvalue, else: iolist()
#    end
#    def intersection(rvalue, type = %Type.List{}) do
#      if Type.subtype?(rvalue, type), do: rvalue, else: none()
#    end
#  end
#
#  subtype :usable_as
#
#  subtract do
#  end
#
#  def normalize([]), do: []
#  def normalize(list), do: normalize(list, [])
#  def normalize([head | rest], so_far) do
#    normalize(rest, [Type.normalize(head) | so_far])
#  end
#  def normalize(type, so_far) do
#    %Type.List{
#      type: Enum.into(so_far, %Type.Union{}),
#      final: Type.normalize(type)}
#  end
end