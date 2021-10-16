defmodule Type.Iolist do
  @moduledoc false

  # this module is a PRIVATE module to segregate the challenging
  # iolist logic away from the Type module.
  # note that the public methods here don't conform to any of the
  # method schemata implemented by any of the other modules.

  import Type, only: :macros

  alias Type.{Bitstring, NonemptyList}

  @ltype Type.union([byte(), binary(), iolist()])
  @final Type.union([], binary())

  # INTERSECTIONS

  def intersection_with([]), do: []
  def intersection_with(list) when is_list(list) do
    Type.intersection(list, iolist())
  end
  def intersection_with(list = %NonemptyList{}) do
    # iolist is byte | binary | iolist
    type = [byte(), binary(), iolist()]
    |> Enum.map(&Type.intersection(&1, list.type))
    |> Type.union

    final = Type.intersection(list.final, @final)

    if final == none() or type == none() do
      none()
    else
      %NonemptyList{type: type, final: final}
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

  def supertype_of_iolist?(union) do
    Type.subtype?(explicit_iolist(), union)
  end

  alias Type.Message

  # USABLE_AS
  def iolist_usable_as(explicit_iolist(), _meta), do: :ok
  def iolist_usable_as(target, meta) do
    Type.usable_as(explicit_iolist(), target, meta)
  end

  @final_type Type.union(binary(), [])
  @inner_type Type.union([binary(), byte(), iolist()])
  def usable_as_iolist(challenge = %NonemptyList{final: final, type: type}, meta) do
    u1 = Type.usable_as(final, @final_type, meta)
    u2 = Type.usable_as(type, @inner_type, meta)

    case Type.ternary_and(u1, u2) do
      :ok -> :ok
      {:maybe, _} -> {:maybe, [Message.make(challenge, iolist(), meta)]}
      {:error, _} -> {:error, Message.make(challenge, iolist(), meta)}
    end
  end
end
