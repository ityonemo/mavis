defmodule Type.Bitstring do
  @enforce_keys [:size, :unit]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    size: non_neg_integer,
    unit: 0..256
  }

  defimpl Type.Properties do
    import Type, only: :macros
    alias Type.{Bitstring, Message}

    use Type.Impl

    def group_compare(%Bitstring{unit: a}, %Bitstring{unit: b}) when a < b, do: :gt
    def group_compare(%Bitstring{unit: a}, %Bitstring{unit: b}) when a > b, do: :lt
    def group_compare(%Bitstring{size: a}, %Bitstring{size: b}) when a < b, do: :gt
    def group_compare(%Bitstring{size: a}, %Bitstring{size: b}) when a > b, do: :lt

    usable_as do
      # empty strings
      def usable_as(%{size: 0, unit: 0}, %Bitstring{size: 0}, _meta), do: :ok
      def usable_as(type = %{size: 0, unit: 0}, target = %Bitstring{}, meta) do
        {:error, Message.make(type, target, meta)}
      end

      # same unit
      def usable_as(challenge = %Bitstring{size: size_a, unit: unit},
                    target = %Bitstring{size: size_b, unit: unit},
                    meta) do

        cond do
          unit == 0 and size_a == size_b ->
            :ok
          unit == 0 ->
            {:error, Message.make(challenge, target, meta)}
          rem(size_a - size_b, unit) != 0 ->
            :foo
          size_b > size_a ->
            {:maybe, [Message.make(challenge, target, meta)]}
          true ->
            :ok
        end
      end

      # same size
      def usable_as(challenge = %Bitstring{size: size, unit: unit_a},
                    target = %Bitstring{size: size, unit: unit_b},
                    meta) do
        cond do
          unit_b == 0 ->
            {:maybe, [Message.make(challenge, target, meta)]}
          unit_a < unit_b ->
            {:maybe, [Message.make(challenge, target, meta)]}
          true ->
            :ok
        end
      end

      # different sizes and units
      def usable_as(challenge = %Bitstring{size: size_a, unit: unit_a},
                    target = %Bitstring{size: size_b, unit: unit_b}, meta) do

        unit_gcd = Integer.gcd(unit_a, unit_b)
        cond do
          unit_b == 0 and rem(size_a - size_b, unit_a) == 0 ->
            {:maybe, [Message.make(challenge, target, meta)]}
          # the lattice formed by the units will never meet.
          rem(size_a - size_b, unit_gcd) != 0 ->
            {:error, Message.make(challenge, target, meta)}
          # the challenge lattice strictly overlays the target lattice
          unit_gcd == unit_b ->
            :ok
          true ->
            {:maybe, [Message.make(challenge, target, meta)]}
        end
      end
    end

    def subtype?(a, b), do: usable_as(a, b, []) == :ok
  end
end
