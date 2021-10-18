defmodule TypeTest.LiteralRange.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of a literal range" do
    @tag :skip
    test "with itself, integer and any is itself" do
      assert -47..47 == -47..47 <~> any()
      assert -47..47 == -47..47 <~> integer()
      assert -47..47 == -47..47 <~> -47..47
    end

    @tag :skip
    test "with integer subsets" do
      # negative ranges
      assert -47..-1        == -47..-1 <~> neg_integer()
      assert none() == -47..-1 <~> pos_integer()
      assert none() == -47..-1 <~> non_neg_integer()

      # straddling ranges
      assert -47..-1 == -47..47 <~> neg_integer()
      assert -1      == -1..1 <~> neg_integer()
      assert 1..47   == -47..47 <~> pos_integer()
      assert 1       == -1..1 <~> pos_integer()
      assert 0..47   == -47..47 <~> non_neg_integer()
      assert 0       == -1..0 <~> non_neg_integer()

      # positive ranges
      assert none() == 1..47 <~> neg_integer()
      assert 1..47          == 1..47 <~> pos_integer()
      assert 1..47          == 1..47 <~> non_neg_integer()
    end

    @tag :skip
    test "with other ranges" do
      # disjoint left
      assert none() == 1..10 <~> 11..12
      # overlapping left
      assert 10             == 1..10 <~> 10..12
      assert 9..10          == 1..10 <~> 9..12
      # internal left
      assert 1..10          == 1..10 <~> 1..12
      # internal center
      assert 1..10          == 1..10 <~> 0..12
      # internal right
      assert 1..10          == 1..10 <~> 0..10
      # overlapping right
      assert 1..2           == 1..10 <~> 0..2
      assert 1              == 1..10 <~> 0..1
      #disjoint right
      assert none() == 1..10 <~> -1..0

      # symmetrical to above
      assert none() == 11..12 <~> 1..10
      assert 10             == 10..12 <~> 1..10
      assert 9..10          == 9..12 <~>  1..10
      assert 1..10          == 1..12 <~>  1..10
      assert 1..10          == 0..12 <~>  1..10
      assert 1..10          == 0..10 <~>  1..10
      assert 1..2           == 0..2 <~>   1..10
      assert 1              == 0..1 <~>   1..10
      assert none() == -1..0 <~>  1..10
    end

    @tag :skip
    test "with integers" do
      assert none() == 1..10 <~> -42
      assert 47 == 0..255 <~> 47
      assert none() == 1..10 <~> 42
    end

    @tag :skip
    test "with unions works as expected" do
      assert (1 <|> 9..10) == 1..10 <~> (0..1 <|> 9..15)
      assert none() == 1..10 <~> (atom() <|> port())
    end

    @tag :skip
    test "with all other types is none" do
      TypeTest.Targets.except([-10..10, pos_integer(), non_neg_integer(), integer()])
      |> Enum.each(fn target ->
        assert none() == 1..10 <~> target
      end)
    end
  end
end
