
defimpl Type.Properties, for: BitString do
  import Type, only: :macros
  use Type.Helpers

  group_compare do
    def group_compare(_, %Type.Bitstring{}), do: :lt
    def group_compare(_, %Type{module: String, name: :t}), do: :lt
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

  alias Type.Message

  usable_as do
    def usable_as(bitstring, target = %Type.Bitstring{}, meta)
        when is_bitstring(bitstring) do
      %Type.Bitstring{size: :erlang.bit_size(bitstring)}
      |> Type.usable_as(target, meta)
      |> case do
        {:error, _} -> {:error, Message.make(bitstring, target, meta)}
        {:maybe, _} -> {:maybe, [Message.make(bitstring, target, meta)]}
        :ok -> :ok
      end
    end
    def usable_as(binary, target = %Type{module: String, name: :t}, meta)
        when is_binary(binary) do
      case target.params do
        [] -> :ok
        [v] when :erlang.size(binary) == v -> :ok
        _ -> {:error, Message.make(binary, target, meta)}
      end
    end
  end

  intersection do
    def intersection(_, bitstring) when is_bitstring(bitstring), do: none()
    def intersection(binary, rhs = %Type{module: String, name: :t})
        when is_binary(binary) do
      case rhs.params do
        [] -> binary
        [v] when :erlang.size(binary) == v -> binary
        _ -> none()
      end
    end
    def intersection(bitstring, type) do
      bitstring
      |> normalize
      |> Type.subtype?(type)
      |> if do
        bitstring
      else
        none()
      end
    end
  end

  subtract do
  end

  def normalize(binary) when is_binary(binary) do
    if String.valid?(binary) do
      remote(String.t())
    else
      %Type.Bitstring{size: :erlang.bit_size(binary)}
    end
  end
  def normalize(bitstring) do
    %Type.Bitstring{size: :erlang.bit_size(bitstring)}
  end
end