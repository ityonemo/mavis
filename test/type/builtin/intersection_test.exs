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

  describe "the intersection of pos_integer" do
    test "with any, integer, and pos_integer, and non_neg_integer is itself" do
      assert builtin(:pos_integer) == Type.intersection(builtin(:pos_integer), builtin(:any))
      assert builtin(:pos_integer) == Type.intersection(builtin(:pos_integer), builtin(:integer))
      assert builtin(:pos_integer) == Type.intersection(builtin(:pos_integer), builtin(:non_neg_integer))
      assert builtin(:pos_integer) == Type.intersection(builtin(:pos_integer), builtin(:pos_integer))
    end

    test "with integers yields the integer only for negative integers" do
      assert 47 == Type.intersection(builtin(:pos_integer), 47)
      assert builtin(:none) == Type.intersection(builtin(:pos_integer), -47)
    end

    test "with ranges trim as expected" do
      assert 1..47 == Type.intersection(builtin(:pos_integer), 1..47)
      assert 1..47 == Type.intersection(builtin(:pos_integer), -47..47)
      assert builtin(:none) == Type.intersection(builtin(:pos_integer), -47..-1)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([47, builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer), -10..10])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:pos_integer), target)
      end)
    end
  end

  describe "the intersection of non_neg_integer" do
    test "with any, integer, and non_neg_integer is itself" do
      assert builtin(:non_neg_integer) == Type.intersection(builtin(:non_neg_integer), builtin(:any))
      assert builtin(:non_neg_integer) == Type.intersection(builtin(:non_neg_integer), builtin(:integer))
      assert builtin(:non_neg_integer) == Type.intersection(builtin(:non_neg_integer), builtin(:non_neg_integer))
    end

    test "with pos_integer is pos_integer" do
      assert builtin(:pos_integer) == Type.intersection(builtin(:non_neg_integer), builtin(:pos_integer))
    end

    test "with integers yields the integer only for negative integers" do
      assert 47 == Type.intersection(builtin(:non_neg_integer), 47)
      assert 0 == Type.intersection(builtin(:non_neg_integer), 0)
      assert builtin(:none) == Type.intersection(builtin(:non_neg_integer), -47)
    end

    test "with ranges trim as expected" do
      assert 0..47 == Type.intersection(builtin(:non_neg_integer), 0..47)
      assert 0..47 == Type.intersection(builtin(:non_neg_integer), -47..47)
      assert builtin(:none) == Type.intersection(builtin(:non_neg_integer), -47..-1)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([0, 47, builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer), -10..10])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:non_neg_integer), target)
      end)
    end
  end

  describe "the intersection of integer" do
    test "with any, integer is itself" do
      assert builtin(:integer) == Type.intersection(builtin(:integer), builtin(:any))
      assert builtin(:integer) == Type.intersection(builtin(:integer), builtin(:integer))
    end

    test "with integer subtypes is themselves" do
      [47, -47..47, builtin(:neg_integer), builtin(:pos_integer), builtin(:non_neg_integer)]
      |> Enum.each(fn type ->
        assert type == Type.intersection(builtin(:integer), type)
      end)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([-47, 0, 47, builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer), -10..10])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:non_neg_integer), target)
      end)
    end
  end

end
