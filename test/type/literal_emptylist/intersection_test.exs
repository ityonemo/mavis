defmodule TypeTest.LiteralEmptyList.IntersectionTest do
  use ExUnit.Case, async: true

  @moduletag :intersection

  import Type, only: [builtin: 1]

  alias Type.List

  describe "the intersection of a literal empty list" do
    test "with itself, general lists and any is itself" do
      assert [] == Type.intersection([], builtin(:any))
      assert [] == Type.intersection([], %List{type: :foo})
      assert [] == Type.intersection([], %List{})
      assert [] == Type.intersection([], [])
    end

    test "with nonempty, or odd-termination final lists is not ok" do
      assert builtin(:none) == Type.intersection([], %List{final: :foo})
      assert builtin(:none) == Type.intersection([], %List{nonempty: true})
    end

    test "with all other types is none" do
      TypeTest.Targets.except([[], %Type.List{}])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection([], target)
      end)
    end
  end
end
