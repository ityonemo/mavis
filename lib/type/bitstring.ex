defmodule Type.Bitstring do
  @moduledoc """
  Handles bitstrings and binaries in the erlang/elixir type system.

  This type has three parameters that define a semilattice over
  the number line which are the allowed number of bits in the bitstrings
  which are members of this type.

  - `size`: minimum size of the bitstring.
  - `unit`: distance between points in the lattice.
  - `unicode`: if the binary must be unicode-encoded

  Roughly speaking, this corresponds to the process of matching the header
  of a binary (size), plus a variable-length payload with recurring features
  of size (unit).

  Note that a zero-size binary type must always be `unicode: true`

  ### Examples:

  - `t:bitstring/0` is equivalent to `%Type.Bitstring{size: 0, unit: 1}`.
  Note that any bitstring type is a subtype of this type.
  - `t:binary/0` is equivalent to `%Type.Bitstring{size: 0, unit: 8}`.
  - A fixed-size binary is `%Type.Bitstring{unit: 0, size: <size>}`.
  - The empty binary (`""`) is `%Type.Bitstring{unit: 0, size: 0, unicode: true}`.
    note this is distinct from the empty binary literal `""`, this is the only type
    with a single member that isn't self-representable.

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

  Some binaries have no intersection, but Mavis will find obscure intersections.

  ```elixir
  iex> Type.intersect(%Type.Bitstring{size: 15, unit: 0}, %Type.Bitstring{size: 3, unit: 0})
  %Type{name: :none}
  iex> Type.intersect(%Type.Bitstring{size: 0, unit: 8}, %Type.Bitstring{size: 16, unit: 4})
  %Type.Bitstring{size: 16, unit: 8}
  iex> Type.intersect(%Type.Bitstring{size: 15, unit: 1}, %Type.Bitstring{size: 0, unit: 8})
  %Type.Bitstring{size: 16, unit: 8}
  iex> Type.intersect(%Type.Bitstring{size: 14, unit: 6}, %Type.Bitstring{size: 16, unit: 8})
  %Type.Bitstring{size: 32, unit: 24}
  ```

  #### union

  Most binary pairs won't have nontrivial unions, but Mavis will find some obscure ones.

  ```elixir
  iex> Type.union(%Type.Bitstring{size: 0, unit: 1}, %Type.Bitstring{size: 15, unit: 8})
  %Type.Bitstring{size: 0, unit: 1}
  iex> Type.union(%Type.Bitstring{size: 25, unit: 8}, %Type.Bitstring{size: 1, unit: 4})
  %Type.Bitstring{size: 1, unit: 4}
  ```

  #### subtype?

  A bitstring type is a subtype of another if its lattice is covered by the other's.

  ```elixir
  iex> Type.subtype?(%Type.Bitstring{size: 16, unit: 8}, %Type.Bitstring{size: 4, unit: 4})
  true
  iex> Type.subtype?(%Type.Bitstring{size: 3, unit: 7}, %Type.Bitstring{size: 12, unit: 6})
  false
  ```

  #### usable_as

  Most bitstrings are at least maybe usable as others, but there are cases where it's impossible.

  ```elixir
  iex> Type.usable_as(%Type.Bitstring{size: 8, unit: 16}, %Type.Bitstring{size: 4, unit: 4})
  :ok
  iex> Type.usable_as(%Type.Bitstring{size: 3, unit: 7}, %Type.Bitstring{size: 12, unit: 6})
  {:maybe, [%Type.Message{meta: [],
                          challenge: %Type.Bitstring{size: 3, unit: 7},
                          target: %Type.Bitstring{size: 12, unit: 6}}]}
  iex> Type.usable_as(%Type.Bitstring{size: 3, unit: 8}, %Type.Bitstring{size: 16, unit: 8})
  {:error, %Type.Message{meta: [],
                         challenge: %Type.Bitstring{size: 3, unit: 8},
                         target: %Type.Bitstring{size: 16, unit: 8}}}
  ```

  """

  use Type.Helpers
  alias Type.Message

  defstruct [size: 0, unit: 0, unicode: false]

  @type t :: %__MODULE__{
    size: non_neg_integer,
    unit: 0..256,
    unicode: boolean
  }

  @none %Type{name: :none}

  # COMPARISONS
  def compare(_, bitstring) when is_bitstring(bitstring), do: :gt
  def compare(%{size: s, unit: u, unicode: false}, %__MODULE__{size: s, unit: u, unicode: true}), do: :gt
  def compare(%{size: s, unit: u, unicode: true}, %__MODULE__{size: s, unit: u, unicode: false}), do: :lt
  def compare(%{unit: 0}, %__MODULE__{unit: b}) when b != 0, do: :lt
  def compare(%{unit: a}, %__MODULE__{unit: 0}) when a != 0, do: :gt
  def compare(%{unit: a}, %__MODULE__{unit: b}) when a < b,  do: :gt
  def compare(%{unit: a}, %__MODULE__{unit: b}) when a > b,  do: :lt
  def compare(%{size: a}, %__MODULE__{size: b}) when a < b,  do: :gt
  def compare(%{size: a}, %__MODULE__{size: b}) when a > b,  do: :lt

  # MERGERS
  def merge(t = %{size: s, unit: u, unicode: uc}, bitstring) when is_bitstring(bitstring) do
    cond do
      uc and !String.valid?(bitstring) -> :nomerge
      (u == 0) and (s != bit_size(bitstring)) -> :nomerge
      (u != 0) and (rem(bit_size(bitstring) - s, u) != 0) -> :nomerge
      true -> {:merge, [t]}
    end
  end
  def merge(%{size: ls, unit: 0, unicode: luc}, %__MODULE__{size: rs, unit: 0, unicode: ruc}) do
    if ls == rs do
      {:merge, [%__MODULE__{size: ls, unit: 0, unicode: luc and ruc}]}
    else
      :nomerge
    end
  end
  def merge(%{size: ls, unit: u, unicode: luc}, %__MODULE__{size: rs, unit: 0, unicode: ruc}) do
    if rem(rs - ls, u) == 0 do
      {:merge, [%__MODULE__{size: ls, unit: u, unicode: luc and ruc}]}
    else
      :nomerge
    end
  end
  def merge(%{size: ls, unit: u, unicode: luc}, %__MODULE__{size: rs, unit: u, unicode: ruc}) do
    make_merged(rs, ls, u, luc and ruc)
  end
  def merge(%{size: ls, unit: lu, unicode: luc}, %__MODULE__{size: rs, unit: ru, unicode: ruc}) do
    lu
    |> Integer.gcd(ru)
    |> case do
      ^lu -> make_merged(rs, ls, lu, luc and ruc)
      ^ru -> make_merged(rs, ls, ru, luc and ruc)
      _other -> :nomerge
    end
  end
  def merge(_, _), do: :nomerge

  defp make_merged(rs, ls, u, uc) do
    if rem(rs - ls, u) == 0 do
      {:merge, [%__MODULE__{size: min(ls, rs), unit: u, unicode: uc}]}
    else
      :nomerge
    end
  end

  # INTERSECTION
  def intersect(%{unit: 0}, %__MODULE__{unit: 0}), do: @none
  def intersect(%{size: asz, unit: 0, unicode: au}, %__MODULE__{size: bsz, unit: unit, unicode: bu})
      when asz >= bsz and rem(asz - bsz, unit) == 0 do
    build(%{size: asz, unit: 0, unicode: au or bu})
  end
  def intersect(%{size: asz, unit: unit, unicode: au}, %__MODULE__{size: bsz, unit: 0, unicode: bu})
      when bsz >= asz and rem(asz - bsz, unit) == 0 do
    build(%{size: bsz, unit: 0, unicode: au or bu})
  end
  def intersect(%{unit: aun}, %__MODULE__{unit: bun}) when aun == 0 or bun == 0, do: @none
  def intersect(%{size: asz, unit: aun, unicode: au}, %__MODULE__{size: bsz, unit: bun, unicode: bu}) do
    r = rem(asz - bsz, Integer.gcd(aun, bun))
    case {r, asz, bsz} do
      {0, asz, bsz} when asz > bsz ->
        build(%{
          size: sizeup(asz, bsz, aun, bun),
          unit: lcm(aun, bun),
          unicode: au or bu
        })
      {0, asz, bsz} ->
        build(%{
          size: sizeup(bsz, asz, bun, aun),
          unit: lcm(aun, bun),
          unicode: au or bu
        })
      _ -> @none
    end
  end
  def intersect(%{size: size, unit: 0, unicode: unicode}, bitstring)
      when is_bitstring(bitstring) and bit_size(bitstring) == size do
    cond do
      is_binary(bitstring) and unicode and String.valid?(bitstring) ->
        bitstring
      not unicode->
        bitstring
      true ->
        @none
    end
  end
  def intersect(%{size: size, unit: unit, unicode: unicode}, bitstring)
      when is_bitstring(bitstring) and rem(bit_size(bitstring) - size, unit) == 0 do
    cond do
      is_binary(bitstring) and unicode and String.valid?(bitstring) ->
        bitstring
      not unicode->
        bitstring
      true ->
        @none
    end
  end
  def intersect(_, _), do: @none

  defp sizeup(asz, bsz, aun, bun) do
    a_mod_b = rem(aun, bun)
    Enum.reduce_while(0..bun-1, asz - bsz, fn idx, acc ->
      if rem(acc, bun) == 0 do
        {:halt, asz + aun * idx}
      else
        {:cont, acc + a_mod_b}
      end
    end)
  end

  defp lcm(a, b), do: div(a * b, Integer.gcd(a, b))

  defp build(fields = %{size: 0, unit: 0}) do
    __MODULE__
    |> struct(fields)
    |> Map.put(:unicode, false)
  end
  defp build(fields) do
    struct(__MODULE__, fields)
  end

  def usable_as(%{size: 0, unit: 0}, "", _meta), do: :ok
  def usable_as(type = %{size: s, unit: u, unicode: uc}, bs, meta) when is_bitstring(bs) do
    bsz = bit_size(bs)
    cond do
      u == 0 and bsz != s ->
        {:error, Message.make(type, bs, meta)}
      u == 0 and uc and String.valid?(bs) ->
        {:maybe, [Message.make(type, bs, meta)]}
      u == 0 and uc ->
        {:error, Message.make(type, bs, meta)}
      u == 0 ->
        {:maybe, [Message.make(type, bs, meta)]}
      rem(bsz - s, u) != 0 ->
        {:error, Message.make(type, bs, meta)}
      uc and String.valid?(bs) ->
        {:maybe, [Message.make(type, bs, meta)]}
      uc ->
        {:error, Message.make(type, bs, meta)}
      true ->
        {:maybe, [Message.make(type, bs, meta)]}
    end
  end
  def usable_as(%{size: 0, unit: 0}, %__MODULE__{size: 0}, _meta), do: :ok
  def usable_as(type = %{size: 0, unit: 0}, target = %__MODULE__{}, meta) do
    {:error, Message.make(type, target, meta)}
  end

  # same unit
  def usable_as(challenge = %{size: size_a, unit: unit},
                target = %__MODULE__{size: size_b, unit: unit},
                meta) do
    cond do
      unit == 0 and size_a == size_b ->
        unicode_usable_as(challenge, target, meta)
      unit == 0 ->
        {:error, Message.make(challenge, target, meta)}
      rem(size_a - size_b, unit) != 0 ->
        {:error, Message.make(challenge, target, meta)}
      size_b > size_a ->
        {:maybe, [Message.make(challenge, target, meta)]}
      true ->
        unicode_usable_as(challenge, target, meta)
    end
  end

  # same size
  def usable_as(challenge = %{size: size, unit: unit_a},
                target = %__MODULE__{size: size, unit: unit_b},
                meta) do
    cond do
      unit_b == 0 ->
        {:maybe, [Message.make(challenge, target, meta)]}
      unit_a == 0 ->
        unicode_usable_as(challenge, target, meta)
      unit_a < unit_b ->
        {:maybe, [Message.make(challenge, target, meta)]}
      true ->
        unicode_usable_as(challenge, target, meta)
    end
  end

  # different sizes and units
  def usable_as(challenge = %{size: size_a, unit: unit_a},
                target = %__MODULE__{size: size_b, unit: unit_b}, meta) do
    unit_gcd = Integer.gcd(unit_a, unit_b)
    cond do
      unit_b == 0 and rem(size_a - size_b, unit_a) == 0 ->
        {:maybe, [Message.make(challenge, target, meta)]}
      # the lattice formed by the units will never meet.
      rem(size_a - size_b, unit_gcd) != 0 ->
        {:error, Message.make(challenge, target, meta)}
      # the challenge lattice strictly overlays the target lattice
      unit_gcd == unit_b and size_b < size_a ->
        unicode_usable_as(challenge, target, meta)
      true ->
        {:maybe, [Message.make(challenge, target, meta)]}
    end
  end

  defp unicode_usable_as(%{unicode: true}, _, _), do: :ok
  defp unicode_usable_as(_, %{unicode: false}, _), do: :ok
  defp unicode_usable_as(challenge, target, meta) do
    {:maybe, [Message.make(challenge, target, meta)]}
  end

  #  # TODO: DRY THIS UP into the Type module.
  #  defp encapsulation_msg(challenge, target) do
  #    """
  #    #{inspect challenge} is an equivalent type to #{inspect target} but it may fail because it is
  #    a remote encapsulation which may require qualifications outside the type system.
  #    """
  #  end
#
  #  subtract do
  #    def subtract(%{size: 0, unit: 0}, ""), do: none()
  #    # when the target type has unit 0
  #    def subtract(%{size: s1, unit: u1}, %__MODULE__{size: s2, unit: 0}) when
  #        s2 >= s1 and rem(s1, u1) == rem(s2, u1) do
#
  #      if s1 != s2 do
  #        for sz when rem(sz, u1) == rem(s1, u1) <- s1..s2 do
  #          %__MODULE__{size: sz, unit: 0}
  #        end
  #      end
  #      |> List.wrap()
  #      |> Kernel.++([%__MODULE__{size: s2 + u1, unit: u1}])
  #      |> Enum.into(%Type.Union{})
  #    end
  #    def subtract(t, %__MODULE__{unit: 0}), do: t
  #    def subtract(%{size: s1, unit: 0}, %__MODULE__{size: s2, unit: u2}) when
  #        s2 <= s1 and rem(s1, u2) == rem(s2, u2), do: none()
  #    def subtract(t = %{size: _, unit: 0}, %__MODULE__{}), do: t
#
  #    def subtract(%{size: s1, unit: u1}, %__MODULE__{size: s2, unit: u2}) do
  #      # pick the common size as lcm(u2, u1)
  #      common_unit = lcm(u1, u2)
  #      (0..common_unit - 1)
  #      |> Enum.filter(&(rem(s1, u1) == rem(&1, u1)))
  #      |> Enum.reject(&(rem(s2, u2) == rem(&1, u2)))
  #      |> Enum.map(&%__MODULE__{size: &1, unit: common_unit})
  #      |> Kernel.++(residuals(s1, s2, u2))
  #      |> Enum.into(%Type.Union{})
  #    end
#
  #    def subtract(t = %{size: s1, unit: u1}, bitstring) when
  #      is_bitstring(bitstring) and
  #      (:erlang.bit_size(bitstring) < s1 or
  #      rem(:erlang.bit_size(bitstring) - s1, u1) != 0), do: t
#
  #    # error guards
  #    def subtract(_, %__MODULE__{}), do: raise "unreachable"
#
  #    defp residuals(s1, s2, u2) when s1 < s2 do
  #      for i when rem(i, u2) == rem(s2, u2) <- s1..(s2 - 1) do
  #        %__MODULE__{size: i}
  #      end
  #    end
  #    defp residuals(_, _, _), do: []
  #  end
#
  #  subtype :usable_as
  #end

  defimpl Inspect do
    def inspect(%{size: 0, unit: 0}, _opts), do: "type(<<>>)"
    def inspect(%{size: 0, unit: 1}, _opts) do
      "bitstring()"
    end
    def inspect(%{size: 0, unit: 8}, _opts) do
      "binary()"
    end
    def inspect(%{size: 0, unit: unit}, _opts) do
      "type(<<_::_*#{unit}>>)"
    end
    def inspect(%{size: size, unit: 0}, _opts) do
      "type(<<_::#{size}>>)"
    end
    def inspect(%{size: size, unit: unit}, _opts) do
      "type(<<_::#{size}, _::_*#{unit}>>)"
    end
  end
end
