defmodule TypeTest.BuiltinAtom.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of atom" do
    test "with any and atom is itself" do
      assert atom() == atom() <~> any()
      assert atom() == atom() <~> atom()
    end

    test "with a literal atom is the literal atom" do
      assert :foo == atom() <~> :foo
    end

    test "with module builtin is module" do
      assert module() == atom() <~> module()
    end

    test "with node builtin is node" do
      assert type(node()) == atom() <~> type(node())
    end

    test "with none is none" do
      assert none() == atom() <~> none()
    end

    test "with all other types is none" do
      [:foo, atom()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == atom() <~> target
      end)
    end
  end
end
