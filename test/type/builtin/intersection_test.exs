defmodule TypeTest.Builtin.IntersectionTest do
  use ExUnit.Case, async: true

  @moduletag :intersection

  import Type, only: [builtin: 1]

  # types in this document are tested in type compare.
  describe "the intersection of none" do
    test "with all other types is none" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:none), target)
      end)
    end
  end

  describe "the intersection of neg_integer" do
    test "with any, integer, and neg_integer is itself" do
      assert builtin(:neg_integer) == Type.intersection(builtin(:neg_integer), builtin(:any))
      assert builtin(:neg_integer) == Type.intersection(builtin(:neg_integer), builtin(:integer))
      assert builtin(:neg_integer) == Type.intersection(builtin(:neg_integer), builtin(:neg_integer))
    end

    test "with integers yields the integer only for negative integers" do
      assert -47 == Type.intersection(builtin(:neg_integer), -47)
      assert builtin(:none) == Type.intersection(builtin(:neg_integer), 47)
    end

    test "with ranges trim as expected" do
      assert -47..-1 == Type.intersection(builtin(:neg_integer), -47..-1)
      assert -47..-1 == Type.intersection(builtin(:neg_integer), -47..47)
      assert builtin(:none) == Type.intersection(builtin(:neg_integer), 1..47)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([-47, builtin(:neg_integer), builtin(:integer), -10..10])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:neg_integer), target)
      end)
    end
  end

end
