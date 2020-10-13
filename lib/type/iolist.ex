defmodule Type.Iolist do
  @moduledoc false

  # this module is a PRIVATE module to segregate the challenging
  # iolist logic away from the Type module.
  # note that the public methods here don't conform to any of the
  # method schemata implemented by any of the other modules.

  import Type, only: :macros

  alias Type.{Bitstring, List, Union}

  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}
  @ltype Enum.into([@char, @binary, builtin(:iolist)], %Union{})
  @final Union.of([], @binary)

  def intersection_with([]), do: []
  def intersection_with(list = %List{}) do
    # iolist is char | binary | iolist
    type = [@char, @binary, builtin(:iolist)]
    |> Enum.map(&Type.intersection(&1, list.type))
    |> Enum.reject(&(&1 == builtin(:none)))
    |> Enum.into(%Union{})

    final = Type.intersection(list.final, @final)

    if final == builtin(:none) or type == builtin(:none) do
      builtin(:none)
    else
      %List{type: type, final: final, nonempty: list.nonempty}
    end
  end
  def intersection_with(_), do: builtin(:none)

  def compare_list(list) do
    case Type.compare(@ltype, list.type) do
      :eq -> Type.compare(@final, list.final)
      ordered -> ordered
    end
  end

  def compare_list_inv(list) do
    case compare_list(list) do
      :gt -> :lt
      :eq -> :eq
      :lt -> :gt
    end
  end
end
