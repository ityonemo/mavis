defmodule TypeTest.LiteralAtom.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  describe "the intersection of a literal atom" do
    test "with itself, atoms, and any is itself" do
      assert :foo == :foo <~> builtin(:any)
      assert :foo == :foo <~> builtin(:atom)
      assert :foo == :foo <~> :foo
    end

    test "with other atoms is none" do
      assert builtin(:none) == :foo <~> :bar
    end

    test "with unions works as expected" do
      assert :foo == :foo <~> (builtin(:atom) <|> builtin(:integer))
      assert builtin(:none) == :foo <~> (builtin(:integer) <|> builtin(:port))
    end

    test "with the none type is none" do
      assert builtin(:none) == :foo <~> builtin(:none)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([:foo, builtin(:atom)])
      |> Enum.each(fn target ->
        assert builtin(:none) == :foo <~> target
      end)
    end
  end
end
