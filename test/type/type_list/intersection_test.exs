defmodule TypeTest.TypeList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  alias Type.List

  describe "normal list" do
    test "intersects with any and self" do
      assert %List{} == Type.intersection(%List{}, builtin(:any))
      assert %List{} == Type.intersection(%List{}, %List{})
    end

    test "intersects with empty list as empty list" do
      assert [] == Type.intersection(%List{}, [])
    end

    test "intersects with another list with the intersection of types" do
      assert %List{type: builtin(:integer)} == Type.intersection(%List{}, %List{type: builtin(:integer)})
      assert %List{type: 47} == Type.intersection(%List{type: 47}, %List{type: builtin(:integer)})
    end

    test "with unions works as expected" do
      assert [] == Type.intersection(%List{}, ([] | builtin(:atom)))
      assert builtin(:none) == Type.intersection(%List{}, (builtin(:atom) | builtin(:port)))
    end

    test "doesn't intersect with anything else" do
      TypeTest.Targets.except([%List{}, []])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(%List{}, target)
      end)
    end
  end

  describe "nonempty list" do
    test "intersects with any and self" do
      assert %List{nonempty: true} == Type.intersection(%List{}, %List{nonempty: true})
      assert %List{nonempty: true} == Type.intersection(%List{nonempty: true}, %List{})
    end

    test "doesn't intersect with empty list" do
      assert builtin(:none) == Type.intersection([], %List{nonempty: true})
      assert builtin(:none) == Type.intersection(%List{nonempty: true}, [])
    end
  end

  describe "list finals" do
    test "are reduced" do
      assert %List{final: builtin(:pos_integer)} == Type.intersection(%List{final: builtin(:pos_integer)}, %List{final: builtin(:integer)})
      assert %List{final: builtin(:pos_integer)} == Type.intersection(%List{final: builtin(:integer)}, %List{final: builtin(:pos_integer)})
    end
  end
end
