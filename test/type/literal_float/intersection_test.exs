defmodule TypeTest.LiteralFloat.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of a literal float" do
    test "with itself, float and any is itself" do
      assert literal(47.0) == literal(47.0) <~> any()
      assert literal(47.0) == literal(47.0) <~> float()
      assert literal(47.0) == literal(47.0) <~> literal(47.0)

      assert literal(47.0) == any() <~> literal(47.0)
      assert literal(47.0) == float() <~> literal(47.0)
    end

    test "with other literal floats" do
      assert none() == literal(42.0) <~> literal(47.0)
    end

    test "with unions works as expected" do
      assert literal(47.0) == literal(47.0) <~> (:foo <|> literal(47.0))
      assert literal(47.0) == literal(47.0) <~> (:foo <|> float())
      assert none() == literal(47.0) <~> (atom() <|> port())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([float()])
      |> Enum.each(fn target ->
        assert none() == literal(47.0) <~> target
      end)
    end
  end
end
