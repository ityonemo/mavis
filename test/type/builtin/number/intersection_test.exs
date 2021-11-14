defmodule TypeTest.BuiltinNumber.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of number" do
    test "with any and number is itself" do
      assert number() == number() <~> any()
      assert number() == number() <~> number()
    end

    test "with any number subtype is the subtype" do
      assert float() == number() <~> float()
      assert integer() == number() <~> integer()
      assert non_neg_integer() == number() <~> non_neg_integer()
      assert pos_integer() == number() <~> pos_integer()
      assert neg_integer() == number() <~> neg_integer()
      assert byte() == number() <~> byte()
      assert arity() == number() <~> arity()
      assert char() == number() <~> char()
      assert -10..10 == number() <~> -10..10
    end

    test "with literals" do
      assert 47.0 == number() <~> 47.0
      assert 47 == number() <~> 47
    end

    test "with none is none" do
      assert none() == number() <~> none()
    end

    test "with all other types is none" do
      [-47, neg_integer(), 0, 47, -10..10, pos_integer(), float(), 47.0, number()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == number() <~> target
      end)
    end
  end
end
