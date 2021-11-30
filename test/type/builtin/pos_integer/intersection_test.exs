defmodule TypeTest.BuiltinPosInteger.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of pos_integer" do
    test "with any, number, integer, and pos_integer is itself" do
      assert pos_integer() == pos_integer() <~> any()
      assert pos_integer() == pos_integer() <~> number()
      assert pos_integer() == pos_integer() <~> integer()
      assert pos_integer() == pos_integer() <~> pos_integer()
    end

    test "with special subtypes are special subtypes" do
      assert 1..255 == pos_integer() <~> byte()
      assert 1..255 == pos_integer() <~> arity()
      assert 1..0x10FFFF == pos_integer() <~> char()
    end

    test "with any range is the trimmed range" do
      assert 1..10 == pos_integer() <~> -10..10
    end

    test "with any pos_integer literal is the literal" do
      assert 47 == pos_integer() <~> 47
    end

    test "with a non-pos-integer is none" do
      assert none() == pos_integer() <~> 0
      assert none() == pos_integer() <~> -47
    end

    test "with none is none" do
      assert none() == pos_integer() <~> none()
    end

    test "with all other types is none" do
      [47, pos_integer(), -10..10]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == pos_integer() <~> target
      end)
    end
  end
end
