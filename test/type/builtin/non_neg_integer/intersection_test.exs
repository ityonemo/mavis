defmodule TypeTest.BuiltinNonNegInteger.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of non_neg_integer" do
    test "with any, number, integer, and non_neg_integer is itself" do
      assert non_neg_integer() == non_neg_integer() <~> any()
      assert non_neg_integer() == non_neg_integer() <~> number()
      assert non_neg_integer() == non_neg_integer() <~> integer()
      assert non_neg_integer() == non_neg_integer() <~> non_neg_integer()
    end

    test "with special subsets are special subsets" do
      assert byte() == non_neg_integer() <~> byte()
      assert arity() == non_neg_integer() <~> arity()
      assert char() == non_neg_integer() <~> char()
    end

    test "with any range is the range" do
      assert 0..10 == non_neg_integer() <~> -10..10
    end

    test "with any non_neg_integer literal is the literal" do
      assert 0 == non_neg_integer() <~> 0
      assert 47 == non_neg_integer() <~> 47
    end

    test "with a neg-integer is none" do
      assert none() == non_neg_integer() <~> -47
    end

    test "with none is none" do
      assert none() == non_neg_integer() <~> none()
    end

    test "with all other types is none" do
      [47, pos_integer(), -10..10]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == non_neg_integer() <~> target
      end)
    end
  end
end
