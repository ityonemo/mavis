
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
    |> Message._rebrand(bitstring, target)
  end

  def usable_as_internal(bitstring, target, meta) do
    {:error, Message.make(bitstring, target, meta)}
  end

  Helpers.algebra_subtype_fun(__MODULE__, :subtype_internal)
  def subtype_internal(str, %Type.Bitstring{size: s, unit: 0, unicode: unicode}) do
    cond do
      bit_size(str) != s -> false
      unicode -> String.valid?(str)
      true -> true
    end
  end
  def subtype_internal(str, %Type.Bitstring{size: s, unit: u, unicode: unicode}) do
    leftover = bit_size(str) - s
    cond do
      leftover < 0 -> false
      rem(leftover, u) != 0 -> false
      unicode -> String.valid?(str)
      true -> true
    end
  end
  def subtype_internal(_, _), do: false
end
