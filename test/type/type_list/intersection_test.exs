defmodule TypeTest.TypeList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.List

  describe "normal list" do
    test "intersects with any and self" do
      assert %List{} == %List{} <~> builtin(:any)
      assert %List{} == %List{} <~> %List{}
    end

    test "intersects with empty list as empty list" do
      assert [] == %List{} <~> []
    end

    test "intersects with another list with the intersection of types" do
      assert %List{type: builtin(:integer)} == %List{} <~> %List{type: builtin(:integer)}
      assert %List{type: 47} == %List{type: 47} <~> %List{type: builtin(:integer)}
    end

    test "with unions works as expected" do
      assert [] == %List{} <~> ([] <|> builtin(:atom))
      assert builtin(:none) == %List{} <~> (builtin(:atom) <|> builtin(:port))
    end

    test "doesn't intersect with anything else" do
      TypeTest.Targets.except([%List{}, []])
      |> Enum.each(fn target ->
        assert builtin(:none) == %List{} <~> target
      end)
    end
  end

  describe "nonempty list" do
    test "intersects with any and self" do
      assert %List{nonempty: true} == %List{} <~> %List{nonempty: true}
      assert %List{nonempty: true} == %List{nonempty: true} <~> %List{}
    end

    test "doesn't intersect with empty list" do
      assert builtin(:none) == [] <~> %List{nonempty: true}
      assert builtin(:none) == %List{nonempty: true} <~> []
    end
  end

  describe "list finals" do
    test "are reduced" do
      assert %List{final: builtin(:pos_integer)} ==
        %List{final: builtin(:pos_integer)} <~> %List{final: builtin(:integer)}
      assert %List{final: builtin(:pos_integer)} ==
        %List{final: builtin(:integer)} <~> %List{final: builtin(:pos_integer)}
    end
  end
end
