defmodule TypeTest.BuiltinArity.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of arity" do
    test "with any, bigger integers, and arity is itself" do
      assert arity() == arity() <~> any()
      assert arity() == arity() <~> integer()
      assert arity() == arity() <~> non_neg_integer()
      assert arity() == arity() <~> arity()
    end

    test "with pos_integer is 1..255" do
      assert 1..255 == arity() <~> pos_integer()
    end

    test "with a crossing range is the upper half" do
      assert 0..10 == arity() <~> -10..10
    end

    test "with a literal arity is the literal arity" do
      assert 4 == arity() <~> 4
    end


    test "with all other types is none" do
      [0, 47, -10..10, pos_integer()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == arity() <~> target
      end)
    end
  end
end
