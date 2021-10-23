defmodule TypeTest.LiteralAtom.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of a literal atom" do
    test "with itself, atoms, and any is itself" do
      assert :foo == :foo <~> any()
      assert :foo == :foo <~> atom()
      assert :foo == :foo <~> :foo
    end

    test "with other atoms is none" do
      assert none() == :foo <~> :bar
    end

    test "with node works is itself if it has node form" do
      assert :nonode@nohost == :nonode@nohost <~> node_type()
      assert none() == :foobar <~> node_type()
    end

    test "with module generally works" do
      assert Kernel == Kernel <~> module()
      assert :foobar == :foobar <~> module()
    end

    test "with unions works as expected" do
      assert :foo == :foo <~> (atom() <|> integer())
      assert none() == :foo <~> (integer() <|> port())
    end

    test "with the none type is none" do
      assert none() == :foo <~> none()
    end

    @tag :skip
    test "with all other types is none" do
      TypeTest.Targets.except([:foo, atom()])
      |> Enum.each(fn target ->
        assert none() == :foo <~> target
      end)
    end
  end
end
