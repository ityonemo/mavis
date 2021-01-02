defprotocol Type.Properties do
  @spec usable_as(Type.t, Type.t, keyword) :: Type.ternary
  def usable_as(subject, target, meta)

  @spec subtype?(Type.t, Type.t) :: boolean
  def subtype?(subject, target)

  @spec compare(Type.t, Type.t) :: :gt | :eq | :lt
  def compare(a, b)

  @spec typegroup(Type.t) :: Type.group
  def typegroup(type)

  @spec intersection(Type.t, Type.t) :: Type.t
  def intersection(ltype, rtype)

  @spec subtract(Type.t, Type.t) :: Type.t
  def subtract(ltype, rtype)

  @spec normalize(Type.t) :: Type.t
  def normalize(type)
end

# remember, the empty list is its own type
defimpl Type.Properties, for: List do
  import Type, only: :macros

  use Type.Helpers

  alias Type.Message

  group_compare do
    def group_compare([], %Type.List{nonempty: ne}), do: (if ne, do: :gt, else: :lt)
    def group_compare(_, %Type.List{}), do: :lt
    def group_compare(rvalue, lvalue)
      when rvalue < lvalue, do: :lt
    def group_compare(rvalue, lvalue)
      when rvalue == lvalue, do: :eq
    def group_compare(rvalue, lvalue)
      when rvalue > lvalue, do: :gt
    def group_compare(_, _), do: :lt
  end

  usable_as do
    def usable_as([], %Type.List{nonempty: false, final: []}, _meta), do: :ok
    def usable_as([], iolist(), _), do: :ok
    def usable_as([], type = %Type.List{}, meta) do
      {:error, Message.make([], type, meta)}
    end
    def usable_as(list, iolist(), meta) when is_list(list) do
      case usable_as_iolist(list) do
        :ok -> :ok
        :error -> {:error, Message.make(list, iolist(), meta)}
      end
    end
    def usable_as(list, type = %Type.List{}, meta) when is_list(list) do
      case Type.List.usable_literal(type, list) do
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
    def intersection([], %Type.List{nonempty: false, final: []}), do: []
    def intersection([], iolist()), do: Type.Iolist.intersection_with([])
    def intersection([], _), do: none()
    def intersection(rvalue, iolist()) do
      if Type.subtype?(rvalue, iolist()), do: rvalue, else: iolist()
    end
    def intersection(rvalue, type = %Type.List{}) do
      if Type.subtype?(rvalue, type), do: rvalue, else: none()
    end
  end

  subtype :usable_as

  def normalize([]), do: []
  def normalize(list), do: normalize(list, [])
  def normalize([head | rest], so_far) do
    normalize(rest, [Type.normalize(head) | so_far])
  end
  def normalize(type, so_far) do
    %Type.List{
      type: Enum.into(so_far, %Type.Union{}),
      nonempty: true,
      final: Type.normalize(type)}
  end
end

defimpl Type.Properties, for: Float do
  import Type, only: :macros
  use Type.Helpers

  group_compare do
    def group_compare(_, float()), do: :lt
    def group_compare(rvalue, lvalue)
      when rvalue < lvalue, do: :lt
    def group_compare(rvalue, lvalue)
      when rvalue == lvalue, do: :eq
    def group_compare(rvalue, lvalue)
      when rvalue > lvalue, do: :gt
    def group_compare(_, _), do: :lt
  end

  ###########################################################################
  ## SUBTYPE

  subtype :usable_as

  ###########################################################################
  ## USABLE_AS

  usable_as do
    def usable_as(_value, float(), _meta), do: :ok
  end

  intersection do
    def intersection(value, float()), do: value
  end

  def normalize(_float), do: float()
end
