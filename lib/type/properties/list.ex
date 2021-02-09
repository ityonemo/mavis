defimpl Type.Properties, for: List do
  import Type, only: :macros

  use Type.Helpers

  alias Type.Message

  group_compare do
    def group_compare(_, %Type.NonemptyList{}), do: :lt
    def group_compare(left, right) when is_list(right) do
      cond do
        left < right -> :lt
        left == right -> :eq
        true -> :gt
      end
    end
  end

  usable_as do
    def usable_as([], iolist(), _), do: :ok
    def usable_as(list, iolist(), meta) when is_list(list) do
      case usable_as_iolist(list) do
        :ok -> :ok
        :error -> {:error, Message.make(list, iolist(), meta)}
      end
    end
    def usable_as([], type = %Type.NonemptyList{}, meta) do
      {:error, Message.make([], type, meta)}
    end
    def usable_as(list, type = %Type.NonemptyList{}, meta) when is_list(list) do
      case Type.NonemptyList.usable_literal(type, list) do
        :ok -> :ok
        {:maybe, _} -> {:maybe, [Message.make(list, type, meta)]}
        {:error, _} -> {:error, Message.make(list, type, meta)}
      end
    end
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

  intersection do
    def intersection([], %Type.NonemptyList{}), do: none()
    def intersection([], iolist()), do: Type.Iolist.intersection_with([])
    def intersection([], _), do: none()
    def intersection(rvalue, iolist()) do
      if Type.subtype?(rvalue, iolist()), do: rvalue, else: iolist()
    end
    def intersection(rvalue, type = %Type.NonemptyList{}) do
      if Type.subtype?(rvalue, type), do: rvalue, else: none()
    end
  end

  subtype :usable_as

  subtract do
  end

  def normalize([]), do: []
  def normalize(list), do: normalize(list, [])
  def normalize([head | rest], so_far) do
    normalize(rest, [Type.normalize(head) | so_far])
  end
  def normalize(type, so_far) do
    %Type.NonemptyList{
      type: Enum.into(so_far, %Type.Union{}),
      final: Type.normalize(type)}
  end
end
