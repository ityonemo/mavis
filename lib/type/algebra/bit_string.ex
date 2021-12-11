
defimpl Type.Algebra, for: BitString do

  import Type, only: :macros

  alias Type.Helpers
  alias Type.Message
  require Helpers

  Helpers.typegroup_fun()

  Helpers.algebra_compare_fun(__MODULE__, :compare_internal)
  def compare_internal(_, %Type.Bitstring{}), do: :lt
  def compare_internal(_, %Type{module: String, name: :t}), do: :lt
  def compare_internal(lstring, rstring) when lstring < rstring, do: :lt
  def compare_internal(lstring, rstring) when lstring > rstring, do: :gt

  Helpers.algebra_merge_fun(__MODULE__, :merge_internal)
  def merge_internal(_, _), do: none()

  Helpers.algebra_intersection_fun(__MODULE__, :intersect_internal)
  def intersect_internal(_, _), do: %Type{name: :none}

  Helpers.algebra_usable_as_fun(__MODULE__, :usable_as_internal)

  def usable_as_internal(bitstring, target = %Type.Bitstring{unicode: true}, meta) do
    if String.valid?(bitstring) do
      usable_as_internal(bitstring, %{target | unicode: false}, meta)
    else
      {:error, Message.make(bitstring, target, meta)}
    end
  end

  def usable_as_internal(bitstring, target = %Type.Bitstring{}, meta) do
    %Type.Bitstring{size: :erlang.bit_size(bitstring)}
    |> Type.usable_as(target, meta)
    |> case do
      {:error, _} -> {:error, Message.make(bitstring, target, meta)}
      {:maybe, _} -> {:maybe, [Message.make(bitstring, target, meta)]}
      :ok -> :ok
    end
  end

  def usable_as_internal(bitstring, target, meta) do
    {:error, Message.make(bitstring, target, meta)}
  end

#  intersection do
#    def intersect(_, bitstring) when is_bitstring(bitstring), do: none()
#    def intersect(binary, rhs = %Type{module: String, name: :t})
#        when is_binary(binary) do
#
#      case {rhs.params, String.valid?(binary)} do
#        {l, _} when length(l) > 1 -> raise "invalid type #{inspect rhs}"
#        {[], true} -> binary
#        {[v], true} when :erlang.size(binary) == v -> binary
#        _ -> none()
#      end
#    end
#    def intersect(bitstring, type) do
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
#      type(String.t())
#    else
#      %Type.Bitstring{size: :erlang.bit_size(binary)}
#    end
#  end
#  def normalize(bitstring) do
#    %Type.Bitstring{size: :erlang.bit_size(bitstring)}
#  end
end
