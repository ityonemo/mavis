defmodule TypeTest.LiteralAtom.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of a literal atom" do
    @tag :skip
    test "with itself, atoms, and any is itself" do
      assert :foo == :foo <~> any()
      assert :foo == :foo <~> atom()
      assert :foo == :foo <~> :foo
    end

    test "with other atoms is none" do
      assert none() == :foo <~> :bar
    end

    @tag :skip
    test "with node works is itself if it has node form" do
      assert :nonode@nohost == :nonode@nohost <~> node_type()
      assert none() == :foobar <~> node_type()
    end

    @tag :skip
    test "with module works if it has module form" do
      assert Kernel == Kernel <~> module()
      assert none() == :foobar <~> module()
    end

    @tag :skip
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
