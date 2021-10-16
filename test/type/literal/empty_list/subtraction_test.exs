defmodule TypeTest.LiteralEmptyList.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :subtraction

  import Type, only: :macros

  alias Type.NonemptyList

  describe "the subtraction from a literal empty list" do
    test "of itself, general lists and any is itself" do
      assert none() == [] - any()
      assert none() == [] - list(:foo)
      assert none() == [] - list()
      assert none() == [] - []
    end

    test "of nonempty, or odd-termination final lists is not ok" do
      assert [] == [] - %NonemptyList{final: :foo}
      assert [] == [] - list(...)
    end

    test "of unions works as expected" do
      assert none() == [] - ([] <|> integer())
      assert [] == [] - (integer() <|> port())
    end

    test "of all other types is none" do
      TypeTest.Targets.except([[], list()])
      |> Enum.each(fn target ->
        assert [] == [] - target
      end)
    end
  end
end
