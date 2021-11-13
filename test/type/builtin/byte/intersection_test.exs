defmodule TypeTest.BuiltinByte.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of byte" do
    test "with any, integer, char, arity, and byte is itself" do
      assert byte() == byte() <~> any()
      assert byte() == byte() <~> integer()
      assert byte() == byte() <~> char()
      assert byte() == byte() <~> arity()
      assert byte() == byte() <~> byte()
    end

    test "with any number is the number" do
      assert 0 == byte() <~> 0
      assert 255 == byte() <~> 255
    end

    test "with an internal range is the range" do
      assert 1..10 == byte() <~> 1..10
    end

    test "with none is none" do
      assert none() == byte() <~> none()
    end

    test "with all other types is none" do
      [0, 47, -10..10, pos_integer()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == byte() <~> target
      end)
    end
  end
end
