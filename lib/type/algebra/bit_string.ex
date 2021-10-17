
defimpl Type.Algebra, for: BitString do

  alias Type.Helpers
  require Helpers

  Helpers.typegroup_fun()
  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)
  Helpers.algebra_intersection_fun(__MODULE__, :intersection_internal)

  def compare_internal(_, %Type.Bitstring{}), do: :lt
  def compare_internal(_, %Type{module: String, name: :t}), do: :lt
  def compare_internal(lstring, rstring) when lstring < rstring, do: :lt
  def compare_internal(lstring, rstring) when lstring > rstring, do: :gt
  def compare_internal(lstring, rstring), do: :eq

  def intersection(_, _) do
    require Type
    Type.none()
  end

#  use Type.Helpers
#
#  group_compare do
#    def group_compare(_, %Type.Bitstring{}), do: :lt
#    def group_compare(_, %Type{module: String, name: :t}), do: :lt
#    def group_compare(rvalue, lvalue)
#      when rvalue < lvalue, do: :lt
#    def group_compare(rvalue, lvalue)
#      when rvalue == lvalue, do: :eq
#    def group_compare(rvalue, lvalue)
#      when rvalue > lvalue, do: :gt
#    def group_compare(_, _), do: :lt
#  end
#
#  ###########################################################################
#  ## SUBTYPE
#
#  subtype :usable_as
#
#  ###########################################################################
#  ## USABLE_AS
#
#  alias Type.Message
#
#  usable_as do
#    def usable_as(bitstring, target = %Type.Bitstring{}, meta)
#        when is_bitstring(bitstring) do
#      %Type.Bitstring{size: :erlang.bit_size(bitstring)}
#      |> Type.usable_as(target, meta)
#      |> case do
#        {:error, _} -> {:error, Message.make(bitstring, target, meta)}
#        {:maybe, _} -> {:maybe, [Message.make(bitstring, target, meta)]}
#        :ok -> :ok
#      end
#    end
#    def usable_as(binary, target = %Type{module: String, name: :t}, meta)
#        when is_binary(binary) do
#      case {target.params, String.valid?(binary)} do
#        {l, _} when length(l) > 1 -> raise "invalid type #{inspect target}"
#        {[], true} -> :ok
#        {[v], true} when :erlang.size(binary) == v -> :ok
#        _ ->
#          {:error, Message.make(binary, target, meta)}
#      end
#    end
#  end
#
#  intersection do
#    def intersection(_, bitstring) when is_bitstring(bitstring), do: none()
#    def intersection(binary, rhs = %Type{module: String, name: :t})
#        when is_binary(binary) do
#
#      case {rhs.params, String.valid?(binary)} do
#        {l, _} when length(l) > 1 -> raise "invalid type #{inspect rhs}"
#        {[], true} -> binary
#        {[v], true} when :erlang.size(binary) == v -> binary
#        _ -> none()
#      end
#    end
#    def intersection(bitstring, type) do
#      %Type.Bitstring{size: :erlang.bit_size(bitstring)}
#      |> Type.subtype?(type)
#      |> if do
#        bitstring
#      else
#        none()
#      end
#    end
#  end
#
#  subtract do
#  end
#
#  def normalize(binary) when is_binary(binary) do
#    if String.valid?(binary) do
#      remote(String.t())
#    else
#      %Type.Bitstring{size: :erlang.bit_size(binary)}
#    end
#  end
#  def normalize(bitstring) do
#    %Type.Bitstring{size: :erlang.bit_size(bitstring)}
#  end
end
