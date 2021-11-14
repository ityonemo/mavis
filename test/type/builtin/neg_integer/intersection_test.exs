defmodule TypeTest.BuiltinNegInteger.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of neg_integer" do
    test "with any, number, integer, and neg_integer is itself" do
      assert neg_integer() == neg_integer() <~> any()
      assert neg_integer() == neg_integer() <~> number()
      assert neg_integer() == neg_integer() <~> integer()
      assert neg_integer() == neg_integer() <~> neg_integer()
    end

    test "with any range is the range" do
      assert -10..-1 == neg_integer() <~> -10..10
    end

    test "with any neg_integer literal is the range" do
      assert -47 == neg_integer() <~> -47
    end

    test "with a non-neg-integer is none" do
      assert none() == neg_integer() <~> 0
      assert none() == neg_integer() <~> 47
    end

    test "with none is none" do
      assert none() == neg_integer() <~> none()
    end

    test "with all other types is none" do
      [-47, neg_integer(), -10..10]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == neg_integer() <~> target
      end)
    end
  end
end
