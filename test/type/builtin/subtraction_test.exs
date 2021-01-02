defmodule TypeTest.Builtin.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the subtraction from none" do
    test "of all other types is none" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == none() - target
      end)
    end
  end

  describe "the subtraction from any" do
    test "is not implemented"
  end

  describe "the subtraction from neg_integer" do
    test "of neg_integer, integer, or any is none" do
      assert none() == neg_integer() - neg_integer()
      assert none() == neg_integer() - integer()
      assert none() == neg_integer() - any()
    end

    test "of integers yields a subtraction only for negative integers" do
      assert %Type.Subtraction{base: neg_integer(), exclude: -47} ==
        neg_integer() - -47
      assert neg_integer() == neg_integer() - 47
    end

    test "with ranges trim as expected" do
      assert %Type.Subtraction{base: neg_integer(), exclude: -47..-10} ==
        neg_integer() - (-47..-10)
      assert %Type.Subtraction{base: neg_integer(), exclude: -47..-1} ==
        neg_integer() - (-47..47)
      assert %Type.Subtraction{base: neg_integer(), exclude: -1} ==
        neg_integer() - (-1..47)
      assert neg_integer() == neg_integer() - (1..47)
    end

    test "with unions works as expected" do
      assert %Type.Subtraction{
        base: neg_integer(),
        exclude: (-1 <|> (-47..-10))} ==
          neg_integer() - ((-47..-10) <|> (-1..47) <|> :foo)
    end

    test "with all other types is unaffected" do
      TypeTest.Targets.except([-47, neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert neg_integer() == neg_integer() - target
      end)
    end
  end

  describe "the subtraction from pos_integer" do
    test "of any, integer, and pos_integer, and non_neg_integer is itself" do
      assert none() == pos_integer() - any()
      assert none() == pos_integer() - integer()
      assert none() == pos_integer() - non_neg_integer()
      assert none() == pos_integer() - pos_integer()
    end

    test "with integers yields a subtraction only for positive integers" do
      assert %Type.Subtraction{base: pos_integer(), exclude: 47} ==
        pos_integer() - 47
      assert pos_integer() == pos_integer() - -47
    end

    test "with ranges trim as expected" do
      assert %Type.Subtraction{base: pos_integer(), exclude: 10..47} ==
        pos_integer() - (10..47)
      assert %Type.Subtraction{base: pos_integer(), exclude: 1..47} ==
        pos_integer() - (1..47)
      assert %Type.Subtraction{base: pos_integer(), exclude: 1} ==
        pos_integer() - (-47..1)
      assert pos_integer() == pos_integer() - (-47..-1)
    end

    test "with unions works as expected" do
      assert %Type.Subtraction{
        base: pos_integer(),
        exclude: (1 <|> (10..47))} ==
          pos_integer() - ((10..47) <|> (-47..1) <|> :foo)
    end

    test "with all other types is unaffected" do
      TypeTest.Targets.except([47, pos_integer(), non_neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert pos_integer() == pos_integer() - target
      end)
    end
  end

end
