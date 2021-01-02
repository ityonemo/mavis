defmodule TypeTest.LiteralAtom.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the subtraction from a literal atom" do
    test "of itself, atoms, and any is itself" do
      assert none() == :foo - any()
      assert none() == :foo - atom()
      assert none() == :foo - :foo
    end

    test "of other atoms is none" do
      assert :foo == :foo - :bar
    end

    test "of node works is itself if it has node form" do
      assert none() == :nonode@nohost - node_type()
      assert :foobar == :foobar - node_type()
    end

    test "of module works if it is a module" do
      assert none() == Kernel - module()
      assert :foobar == :foobar - module()
    end

    test "of unions works as expected" do
      assert none() == :foo - (atom() <|> integer())
      assert :foo == :foo - (integer() <|> port())
    end

    test "of the none type is none" do
      assert none() == :foo <~> none()
    end

    test "of all other types is unchanged" do
      TypeTest.Targets.except([:foo, atom()])
      |> Enum.each(fn target ->
        assert :foo == :foo - target
      end)
    end
  end
end
