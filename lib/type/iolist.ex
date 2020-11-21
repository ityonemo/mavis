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
  @ltype Type.union([@char, @binary, iolist()])
  @final Type.union([], @binary)

  # INTERSECTIONS

  def intersection_with([]), do: []
  def intersection_with(list = %List{}) do
    # iolist is char | binary | iolist
    type = [@char, @binary, iolist()]
    |> Enum.map(&Type.intersection(&1, list.type))
    |> Type.union

    final = Type.intersection(list.final, @final)

    if final == none() or type == none() do
      none()
    else
      %List{type: type, final: final, nonempty: list.nonempty}
    end
  end
  def intersection_with(_), do: none()

  # COMPARISONS

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

  # SUBTYPE

  def subtype_of_iolist?(list) do
    Type.subtype?(list.type, @ltype) and Type.subtype?(list.final, @final)
  end

  def supertype_of_iolist?(list) do
    Type.subtype?(@ltype, list.type) and Type.subtype?(@final, list.final)
      and not list.nonempty
  end

  alias Type.Message

  # USABLE_AS
  def usable_as_list(target = %List{nonempty: true}, meta) do
    u1 = Type.usable_as(@ltype, target.type, meta)
    u2 = Type.usable_as(@final, target.final, meta)

    case Type.ternary_and(u1, u2) do
      :ok -> {:maybe, [Message.make(iolist(), target, meta)]}
      # TODO: make this report the internal error as well.
      {:maybe, _} -> {:maybe, [Message.make(iolist(), target, meta)]}
      {:error, _} -> {:error, Message.make(iolist(), target, meta)}
    end
  end
  def usable_as_list(target, meta) do
    case Type.usable_as(@ltype, target.type, meta) do
      {:error, _} -> {:maybe, [Message.make(@ltype, target.type, meta)]}
      any -> any
    end
    |> Type.ternary_and(Type.usable_as(@final, target.final, meta))
    |> case do
      :ok -> :ok
      {:maybe, _} -> {:maybe, [Message.make(iolist(), target, meta)]}
      {:error, _} -> {:error, Message.make(iolist(), target, meta)}
    end
  end

  def usable_as_iolist(challenge = %{nonempty: nonempty}, meta) do
    case Type.usable_as(challenge.type, @ltype, meta) do
      {:error, _} when not nonempty ->
        {:maybe, [Message.make(challenge.type, @ltype, meta)]}
      any -> any
    end
    |> Type.ternary_and(Type.usable_as(challenge.final, @final, meta))
    |> case do
      :ok -> :ok
      {:maybe, _} -> {:maybe, [Message.make(challenge, iolist(), meta)]}
      {:error, _} -> {:error, Message.make(challenge, iolist(), meta)}
    end
  end
end
