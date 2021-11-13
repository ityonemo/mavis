defmodule TypeTest.BuiltinChar.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of char" do
    test "with any, integer, char, arity, and char is itself" do
      assert char() == char() <~> any()
      assert char() == char() <~> integer()
      assert char() == char() <~> char()
    end

    test "with any number is the number" do
      assert 0 == char() <~> 0
      assert 0x10FFF == char() <~> 0x10FFF
    end

    test "with an internal range is the range" do
      assert 1..10 == char() <~> 1..10
    end

    test "with byte is byte" do
      assert byte() == char() <~> byte()
    end

    test "with none is none" do
      assert none() == char() <~> none()
    end

    test "with all other types is none" do
      [0, 47, -10..10, pos_integer()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == char() <~> target
      end)
    end
  end
end
