defmodule TypeTest.BuiltinNode.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of node" do
    test "with any, atom, and node is itself" do
      assert node() == node() <~> any()
      assert node() == node() <~> atom()
      assert node() == node() <~> node()
    end

    test "with a conformant atom literal is the literal" do
      assert :foo@bar == node() <~> :foo@bar
    end

    test "with a non-conformant atom literal is none" do
      assert none() == node() <~> :foo
    end

    test "with none is none" do
      assert none() == node() <~> none()
    end

    test "with all other types is none" do
      [atom()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == node() <~> target
      end)
    end
  end
end
