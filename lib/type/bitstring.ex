defmodule Type.Bitstring do
  @enforce_keys [:size, :unit]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
    size: non_neg_integer,
    unit: 0..256
  }

  defimpl Type.Typed do
    import Type, only: :macros

    alias Type.Bitstring

    def coercion(_, builtin(:any)), do: :type_ok
    def coercion(any, any), do: :type_ok

    # zero types
    def coercion(%Bitstring{size: 0, unit: 0}, %Bitstring{size: 0}) do
      :type_ok
    end
    def coercion(%Bitstring{size: 0, unit: 0}, %Bitstring{}) do
      :type_maybe
    end

    # into zero type
    def coercion(%Bitstring{size: 0}, %Bitstring{size: 0, unit: 0}) do
      :type_maybe
    end

    # same unit
    def coercion(%Bitstring{size: size_a, unit: unit},
                 %Bitstring{size: size_b, unit: unit})
                 when unit > 0 and rem(size_a - size_b, unit) == 0 do
      if size_a > size_b do
        :type_maybe
      else
        :type_ok
      end
    end
    def coercion(%Bitstring{unit: unit}, %Bitstring{unit: unit}) do
      :type_error
    end

    # same size
    def coercion(%Bitstring{size: size, unit: unit_a},
                 %Bitstring{size: size, unit: unit_b})
                 when unit_a > 0 and rem(unit_a, unit_b) == 0 do
      :type_ok
    end

    # first unit has size zero
    def coercion(%Bitstring{size: size_a, unit: 0},
                 %Bitstring{size: size_b, unit: unit})
                 when size_b <= size_a and rem(size_a - size_b, unit) == 0 do
      :type_ok
    end
    def coercion(%Bitstring{unit: 0}, %Bitstring{}) do
      :type_error
    end

    # second unit has size zero
    def coercion(%Bitstring{size: size_a, unit: unit},
                 %Bitstring{size: size_b, unit: 0})
                 when size_a <= size_b and rem(size_b - size_a, unit) == 0 do
      :type_ok
    end
    def coercion(_, %Bitstring{unit: 0}) do
      :type_error
    end

    # heteregenous sizes and units
    def coercion(%Bitstring{size: size_a, unit: unit_a},
                 %Bitstring{size: size_b, unit: unit_b}) do
      cond do
        rem(size_a - size_b, Integer.gcd(unit_a, unit_b)) != 0 ->
          :type_error
        unit_b > unit_a ->
          :type_maybe
        true ->
          :type_ok
      end
    end

    def coercion(_, _), do: :type_error
  end
end
