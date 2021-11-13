defmodule TypeTest.BuiltinInteger.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of integer" do
    test "with any, number, and integer is itself" do
      assert integer() == integer() <~> any()
      assert integer() == integer() <~> number()
      assert integer() == integer() <~> integer()
    end

    test "with any integer subtype is the subtype" do
      # primitives
      assert pos_integer() == integer() <~> pos_integer()
      assert non_neg_integer() == integer() <~> non_neg_integer()
      assert neg_integer() == integer() <~> neg_integer()

      # builtins
      assert byte() == integer() <~> byte()
      assert arity() == integer() <~> arity()
      assert char() == integer() <~> char()
    end

    test "with any range is the range" do
      assert -10..10 == integer() <~> -10..10
    end

    test "with any integer literal is the range" do
      assert -47 == integer() <~> -47
      assert 0 == integer() <~> 0
      assert 47 == integer() <~> 47
    end

    test "with none is none" do
      assert none() == integer() <~> none()
    end

    test "with all other types is none" do
      [-47, neg_integer(), 0, 47, -10..10, pos_integer()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == integer() <~> target
      end)
    end
  end
end
