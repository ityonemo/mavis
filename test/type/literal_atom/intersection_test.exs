defmodule TypeTest.LiteralAtom.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  describe "the intersection of a literal atom" do
    test "with itself, atoms, and any is itself" do
      assert :foo == Type.intersection(:foo, builtin(:any))
      assert :foo == Type.intersection(:foo, builtin(:atom))
      assert :foo == Type.intersection(:foo, :foo)
    end

    test "with other atoms is none" do
      assert builtin(:none) == Type.intersection(:foo, :bar)
    end

    test "with unions works as expected" do
      assert :foo == Type.intersection(:foo, (builtin(:atom) <|> builtin(:integer)))
      assert builtin(:none) == Type.intersection(:foo, (builtin(:integer) <|> builtin(:port)))
    end

    test "with the none type is none" do
      assert builtin(:none) == Type.intersection(:foo, builtin(:none))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([:foo, builtin(:atom)])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(:foo, target)
      end)
    end
  end
end
