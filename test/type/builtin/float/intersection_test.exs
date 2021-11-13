defmodule TypeTest.BuiltinFloat.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of float" do
    test "with any, number, and float is itself" do
      assert float() == float() <~> any()
      assert float() == float() <~> number()
      assert float() == float() <~> float()
    end

    test "with any number is the number" do
      assert 0.0 == float() <~> 0.0
    end

    test "with an integer is none" do
      assert none() == float() <~> 42
    end

    test "with none is none" do
      assert none() == float() <~> none()
    end

    test "with all other types is none" do
      [47.0, float()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == float() <~> target
      end)
    end
  end
end
