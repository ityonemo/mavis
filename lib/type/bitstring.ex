defmodule Type.Bitstring do
  @moduledoc """
  Handles bitstrings and binaries in the erlang/elixir type system.

  This type has two required parameters that define a semilattice over
  the number line which are the allowed number of bits in the bitstrings
  which are members of this type.

  - `size` minimum size of the bitstring.
  - `unit` distance between points in the lattice.

  Roughly speaking, this corresponds to the process of matching the header
  of a binary (size), plus a variable-length payload with recurring features
  of size (unit).

  ### Examples:

  - `t:bitstring/0` is equivalent to `%Type.Bitstring{size: 0, unit: 1}`.
  Note that any bitstring type is a subtype of this type.
  - `t:binary/0` is equivalent to `%Type.Bitstring{size: 0, unit: 8}`.
  - A fixed-size binary is `%Type.Bitstring{unit: 0, size: <size>}`.
  - The empty binary (`""`) is `%Type.Bitstring{unit: 0, size: 0}`.

  ### Key functions:

  #### comparison

  binaries are sorted by unit first (with smaller units coming after bigger units,
  as they are less restrictive), except zero, which is the most restrictive.

  ```elixir
  iex> Type.compare(%Type.Bitstring{size: 0, unit: 8}, %Type.Bitstring{size: 0, unit: 1})
  :lt
  iex> Type.compare(%Type.Bitstring{size: 0, unit: 1}, %Type.Bitstring{size: 16, unit: 0})
  :gt
  ```

  for two binaries with the same unit, a binary with a smaller fixed size comes
  after those with bigger fixed sizes, since bigger fixed sizes are more restrictive.

  ```elixir
  iex> Type.compare(%Type.Bitstring{size: 0, unit: 8}, %Type.Bitstring{size: 16, unit: 8})
  :gt
  iex> Type.compare(%Type.Bitstring{size: 16, unit: 8}, %Type.Bitstring{size: 8, unit: 8})
  :lt
  ```

  #### intersection

  some binaries have no intersection, but mavis will find obscure intersections.

  ```elixir
  iex> Type.intersection(%Type.Bitstring{size: 15, unit: 0}, %Type.Bitstring{size: 3, unit: 0})
  %Type{name: :none}
  iex> Type.intersection(%Type.Bitstring{size: 0, unit: 8}, %Type.Bitstring{size: 16, unit: 4})
  %Type.Bitstring{size: 16, unit: 8}
  iex> Type.intersection(%Type.Bitstring{size: 15, unit: 1}, %Type.Bitstring{size: 0, unit: 8})
  %Type.Bitstring{size: 16, unit: 8}
  iex> Type.intersection(%Type.Bitstring{size: 14, unit: 6}, %Type.Bitstring{size: 16, unit: 8})
  %Type.Bitstring{size: 32, unit: 24}
  ```

  #### union

  most binary pairs won't have nontrivial unions, but mavis will find some obscure ones.

  ```elixir
  iex> Type.union(%Type.Bitstring{size: 0, unit: 1}, %Type.Bitstring{size: 15, unit: 8})
  %Type.Bitstring{size: 0, unit: 1}
  iex> Type.union(%Type.Bitstring{size: 25, unit: 8}, %Type.Bitstring{size: 1, unit: 4})
  %Type.Bitstring{size: 1, unit: 4}
  ```

  #### subtype?

  a bitstring type is a subtype of another if its lattice is covered by the other's

  ```elixir
  iex> Type.subtype?(%Type.Bitstring{size: 16, unit: 8}, %Type.Bitstring{size: 4, unit: 4})
  true
  iex> Type.subtype?(%Type.Bitstring{size: 3, unit: 7}, %Type.Bitstring{size: 12, unit: 6})
  false
  ```

  #### usable_as

  most bitstrings are at least maybe usable as others, but there are cases where it's impossible

  ```elixir
  iex> Type.usable_as(%Type.Bitstring{size: 8, unit: 16}, %Type.Bitstring{size: 4, unit: 4})
  :ok
  iex> Type.usable_as(%Type.Bitstring{size: 3, unit: 7}, %Type.Bitstring{size: 12, unit: 6})
  {:maybe, [%Type.Message{meta: [],
                          type: %Type.Bitstring{size: 3, unit: 7},
                          target: %Type.Bitstring{size: 12, unit: 6}}]}
  iex> Type.usable_as(%Type.Bitstring{size: 3, unit: 8}, %Type.Bitstring{size: 16, unit: 8})
  {:error, %Type.Message{meta: [],
                         type: %Type.Bitstring{size: 3, unit: 8},
                         target: %Type.Bitstring{size: 16, unit: 8}}}
  ```

  """

  defstruct [size: 0, unit: 0]

  @type t :: %__MODULE__{
    size: non_neg_integer,
    unit: 0..256
  }

  defimpl Type.Properties do
    import Type, only: :macros
    alias Type.{Bitstring, Message}

    use Type.Helpers

    group_compare do
      def group_compare(%Bitstring{unit: 0}, %Bitstring{unit: b}) when b != 0, do: :lt 
      def group_compare(%Bitstring{unit: a}, %Bitstring{unit: 0}) when a != 0, do: :gt 
      def group_compare(%Bitstring{unit: a}, %Bitstring{unit: b}) when a < b,  do: :gt 
      def group_compare(%Bitstring{unit: a}, %Bitstring{unit: b}) when a > b,  do: :lt 
      def group_compare(%Bitstring{size: a}, %Bitstring{size: b}) when a < b,  do: :gt 
      def group_compare(%Bitstring{size: a}, %Bitstring{size: b}) when a > b,  do: :lt 

      def group_compare(left, %Type{module: String, name: :t}) do
        left
        |> group_compare(%Type.Bitstring{size: 0, unit: 8})
        |> case do
          :eq -> :gt
          order -> order
        end
      end
    end

    usable_as do
      # empty strings
      def usable_as(%{size: 0, unit: 0}, %Bitstring{size: 0}, _meta), do: :ok
      def usable_as(type = %{size: 0, unit: 0}, target = %Bitstring{}, meta) do
        {:error, Message.make(type, target, meta)}
      end

      # same unit
      def usable_as(challenge = %{size: size_a, unit: unit},
                    target = %Bitstring{size: size_b, unit: unit},
                    meta) do

        cond do
          unit == 0 and size_a == size_b ->
            :ok
          unit == 0 ->
            {:error, Message.make(challenge, target, meta)}
          rem(size_a - size_b, unit) != 0 ->
            {:error, Message.make(challenge, target, meta)}
          size_b > size_a ->
            {:maybe, [Message.make(challenge, target, meta)]}
          true ->
            :ok
        end
      end

      # same size
      def usable_as(challenge = %{size: size, unit: unit_a},
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
      def usable_as(challenge = %{size: size_a, unit: unit_a},
                    target = %Bitstring{size: size_b, unit: unit_b}, meta) do

        unit_gcd = Integer.gcd(unit_a, unit_b)
        cond do
          unit_b == 0 and rem(size_a - size_b, unit_a) == 0 ->
            {:maybe, [Message.make(challenge, target, meta)]}
          # the lattice formed by the units will never meet.
          rem(size_a - size_b, unit_gcd) != 0 ->
            {:error, Message.make(challenge, target, meta)}
          # the challenge lattice strictly overlays the target lattice
          unit_gcd == unit_b and size_b < size_a ->
            :ok
          true ->
            {:maybe, [Message.make(challenge, target, meta)]}
        end
      end

      def usable_as(%{size: 0, unit: 0},
                    %Type{module: String, name: :t, params: []}, _meta), do: :ok

      def usable_as(%{size: 0, unit: 0},
                    challenge = %Type{module: String, name: :t, params: [p]}, meta) do
        if Type.subtype?(0, p) do
          :ok
        else
          {:error, Message.make(%Type.Bitstring{}, challenge, meta)}
        end
      end

      def usable_as(challenge, target = %Type{module: String, name: :t, params: []}, meta) do
        case Type.usable_as(challenge, builtin(:binary)) do
          :ok ->
            msg = encapsulation_msg(challenge, target)
            {:maybe, [Message.make(challenge, remote(String.t()), meta ++ [message: msg])]}
          error ->
            error
        end
      end

      def usable_as(challenge, target = %Type{module: String, name: :t, params: [p]}, meta) do
        case p do
          i when is_integer(i) -> [i]
          range = _.._ -> range
          %Type.Union{of: ints} -> ints
        end
        |> Enum.map(&Type.usable_as(challenge, %Type.Bitstring{size: &1 * 8}, meta))
        |> Enum.reduce(&Type.ternary_and/2)
        |> case do
          :ok ->
            msg = encapsulation_msg(challenge, target)
            {:maybe, [Message.make(challenge, remote(String.t()), meta ++ [message: msg])]}
          other -> other
        end
      end
    end

    # TODO: DRY THIS UP into the Type module.
    defp encapsulation_msg(challenge, target) do
      """
      #{inspect challenge} is an equivalent type to #{inspect target} but it may fail because it is
      a remote encapsulation which may require qualifications outside the type system.
      """
    end

    intersection do
      def intersection(%{unit: 0}, %Bitstring{unit: 0}), do: builtin(:none)
      def intersection(%{size: asz, unit: 0}, %Bitstring{size: bsz, unit: unit})
          when asz >= bsz and rem(asz - bsz, unit) == 0 do
        %Bitstring{size: asz, unit: 0}
      end
      def intersection(%{size: asz, unit: unit}, %Bitstring{size: bsz, unit: 0})
          when bsz >= asz and rem(asz - bsz, unit) == 0 do
        %Bitstring{size: bsz, unit: 0}
      end
      def intersection(%{unit: aun}, %Bitstring{unit: bun})
        when aun == 0 or bun == 0 do
        builtin(:none)
      end
      def intersection(%{size: asz, unit: aun}, %Bitstring{size: bsz, unit: bun}) do
        if rem(asz - bsz, Integer.gcd(aun, bun)) == 0 do
          size = if asz > bsz do
            sizeup(asz, bsz, aun, bun)
          else
            sizeup(bsz, asz, bun, aun)
          end
          %Bitstring{
            size: size,
            unit: lcm(aun, bun)}
        else
          builtin(:none)
        end
      end
      def intersection(bs, st = %Type{module: String, name: :t}) do
        Type.intersection(st, bs)
      end
    end

    defp sizeup(asz, bsz, aun, bun) do
      a_mod_b = rem(aun, bun)
      Enum.reduce(0..bun-1, asz - bsz, fn idx, acc ->
        if rem(acc, bun) == 0 do
          throw idx
        else
          acc + a_mod_b
        end
      end)
      raise "unreachable"
    catch
      idx ->
        asz + aun * idx
    end

    defp lcm(a, b), do: div(a * b, Integer.gcd(a, b))

    subtype :usable_as
  end

  defimpl Inspect do
    def inspect(%{size: 0, unit: 0}, _opts), do: "<<>>"
    def inspect(%{size: 0, unit: 1}, _opts) do
      "bitstring()"
    end
    def inspect(%{size: 0, unit: 8}, _opts) do
      "binary()"
    end
    def inspect(%{size: 0, unit: unit}, _opts) do
      "<<_::_*#{unit}>>"
    end
    def inspect(%{size: size, unit: 0}, _opts) do
      "<<_::#{size}>>"
    end
    def inspect(%{size: size, unit: unit}, _opts) do
      "<<_::#{size}, _::_*#{unit}>>"
    end
  end
end
