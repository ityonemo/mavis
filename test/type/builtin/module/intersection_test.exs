defmodule TypeTest.BuiltinModule.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of module" do
    test "with any, atom, and module is itself" do
      assert module() == module() <~> any()
      assert module() == module() <~> atom()
      assert module() == module() <~> module()
    end

    test "with an atom literal is the literal" do
      assert :foo == module() <~> :foo
    end

    test "with none is none" do
      assert none() == module() <~> none()
    end

    test "with all other types is none" do
      [atom(), :foo]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == module() <~> target
      end)
    end
  end
end
