defmodule TypeTest.LiteralInteger.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of a literal integer" do
    test "with itself, integer and any is itself" do
      assert 47 == 47 <~> any()
      assert 47 == 47 <~> integer()
      assert 47 == 47 <~> 47
    end

    test "with integer types is correct" do
      assert -47 == -47 <~> neg_integer()
      assert none() == -47 <~> pos_integer()
      assert none() == -47 <~> non_neg_integer()

      assert none() == 0 <~> neg_integer()
      assert none() == 0 <~> pos_integer()
      assert 0 == 0 <~> non_neg_integer()

      assert none() == 47 <~> neg_integer()
      assert 47 == 47 <~> pos_integer()
      assert 47 == 47 <~> non_neg_integer()
    end

    test "with ranges is correct" do
      assert 47 == 47 <~> 0..50
      assert none() == 42 <~> 0..10
    end

    test "with unions works as expected" do
      assert 47 == 47 <~> (integer() <|> :infinity)
      assert none() == 47 <~> (atom() <|> port())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([integer(), pos_integer(), non_neg_integer()])
      |> Enum.each(fn target ->
        assert none() == 42 <~> target
      end)
    end
  end
end
