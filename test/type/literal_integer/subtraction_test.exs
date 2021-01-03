defmodule TypeTest.LiteralInteger.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the subtraction from a literal integer" do
    test "of itself, integer and any is itself" do
      assert none() == 47 - any()
      assert none() == 47 - integer()
      assert none() == 47 - 47
    end

    test "of integer types is correct" do
      assert none() == -47 - neg_integer()
      assert -47 == -47 - pos_integer()
      assert -47 == -47 - non_neg_integer()

      assert 0 == 0 - neg_integer()
      assert 0 == 0 - pos_integer()
      assert none() == 0 - non_neg_integer()

      assert 47 == 47 - neg_integer()
      assert none() == 47 - pos_integer()
      assert none() == 47 - non_neg_integer()
    end

    test "of ranges is correct" do
      assert none() == 47 - (0..50)
      assert 47 == 47 - (0..10)
    end

    test "of unions works as expected" do
      assert none() == 47 - (integer() <|> :infinity)
      assert 47 == 47 - (atom() <|> port())
    end

    test "of all other types is none" do
      TypeTest.Targets.except([47, integer(), pos_integer(), non_neg_integer()])
      |> Enum.each(fn target ->
        assert 47 == 47 - target
      end)
    end
  end
end
