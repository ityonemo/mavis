defmodule TypeTest.LiteralFloat.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of a literal float" do
    @tag :skip
    test "with itself, float and any is itself" do
      assert 47.0 == 47.0 <~> any()
      assert 47.0 == 47.0 <~> float()
      assert 47.0 == 47.0 <~> 47.0
    end

    @tag :skip
    test "with other literal floats" do
      assert none() == 42.0 <~> 47.0
    end

    @tag :skip
    test "with unions works as expected" do
      assert 47.0 == 47.0 <~> (:foo <|> 47.0)
      assert 47.0 == 47.0 <~> (:foo <|> float())
      assert none() == 47.0 <~> (atom() <|> port())
    end

    @tag :skip
    test "with all other types is none" do
      TypeTest.Targets.except([float(), 47.0])
      |> Enum.each(fn target ->
        assert none() == 47.0 <~> target
      end)
    end
  end
end
