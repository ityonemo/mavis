defmodule TypeTest.LiteralFloat.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :subtraction

  import Type, only: :macros

  describe "the subtraction from a literal float" do
    test "of itself, float and any is itself" do
      assert none() == 47.0 - any()
      assert none() == 47.0 - float()
      assert none() == 47.0 - 47.0
    end

    test "of other literal floats" do
      assert 42.0 == 42.0 - 47.0
    end

    test "of unions works as expected" do
      assert none() == 47.0 - (:foo <|> 47.0)
      assert none() == 47.0 - (:foo <|> float())
      assert 47.0 == 47.0 - (atom() <|> port())
    end

    test "of all other types is none" do
      TypeTest.Targets.except([float(), 47.0])
      |> Enum.each(fn target ->
        assert 47.0 == 47.0 - target
      end)
    end
  end
end
