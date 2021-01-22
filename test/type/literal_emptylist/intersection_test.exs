defmodule TypeTest.LiteralEmptyList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.NonemptyList

  describe "the intersection of a literal empty list" do
    test "with itself, general lists and any is itself" do
      assert [] == [] <~> any()
      assert [] == [] <~> list(:foo)
      assert [] == [] <~> list()
      assert [] == [] <~> []
    end

    test "with nonempty, or odd-termination final lists is not ok" do
      assert none() == [] <~> %List{final: :foo}
      assert none() == [] <~> list(...)
    end

    test "with unions works as expected" do
      assert [] == [] <~> ([] <|> integer())
      assert none() == [] <~> (integer() <|> port())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([[], list()])
      |> Enum.each(fn target ->
        assert none() == [] <~> target
      end)
    end
  end
end
