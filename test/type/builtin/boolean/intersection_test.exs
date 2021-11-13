defmodule TypeTest.BuiltinBoolean.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of boolean" do
    test "with any, boolean, and boolean is itself" do
      assert boolean() == boolean() <~> any()
      assert boolean() == boolean() <~> boolean()
    end

    test "with a boolean is the boolean" do
      assert true == boolean() <~> true
      assert false == boolean() <~> false
    end

    test "with none is none" do
      assert none() == boolean() <~> none()
    end

    test "with all other types is none" do
      atom()
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == boolean() <~> target
      end)
    end
  end
end
