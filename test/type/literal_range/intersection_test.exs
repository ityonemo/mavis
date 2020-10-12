defmodule TypeTest.LiteralRange.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  describe "the intersection of a literal range" do
    test "with itself, integer and any is itself" do
      assert -47..47 == Type.intersection(-47..47, builtin(:any))
      assert -47..47 == Type.intersection(-47..47, builtin(:integer))
      assert -47..47 == Type.intersection(-47..47, -47..47)
    end

    test "with integer subsets" do
      # negative ranges
      assert -47..-1        == Type.intersection(-47..-1, builtin(:neg_integer))
      assert builtin(:none) == Type.intersection(-47..-1, builtin(:pos_integer))
      assert builtin(:none) == Type.intersection(-47..-1, builtin(:non_neg_integer))

      # straddling ranges
      assert -47..-1 == Type.intersection(-47..47, builtin(:neg_integer))
      assert -1      == Type.intersection(-1..1, builtin(:neg_integer))
      assert 1..47   == Type.intersection(-47..47, builtin(:pos_integer))
      assert 1       == Type.intersection(-1..1, builtin(:pos_integer))
      assert 0..47   == Type.intersection(-47..47, builtin(:non_neg_integer))
      assert 0       == Type.intersection(-1..0, builtin(:non_neg_integer))

      # positive ranges
      assert builtin(:none) == Type.intersection(1..47, builtin(:neg_integer))
      assert 1..47          == Type.intersection(1..47, builtin(:pos_integer))
      assert 1..47          == Type.intersection(1..47, builtin(:non_neg_integer))
    end

    test "with other ranges" do
      # disjoint left
      assert builtin(:none) == Type.intersection(1..10, 11..12)
      # overlapping left
      assert 10             == Type.intersection(1..10, 10..12)
      assert 9..10          == Type.intersection(1..10, 9..12)
      # internal left
      assert 1..10          == Type.intersection(1..10, 1..12)
      # internal center
      assert 1..10          == Type.intersection(1..10, 0..12)
      # internal right
      assert 1..10          == Type.intersection(1..10, 0..10)
      # overlapping right
      assert 1..2           == Type.intersection(1..10, 0..2)
      assert 1              == Type.intersection(1..10, 0..1)
      #disjoint right
      assert builtin(:none) == Type.intersection(1..10, -1..0)

      # symmetrical to above
      assert builtin(:none) == Type.intersection(11..12, 1..10)
      assert 10             == Type.intersection(10..12, 1..10)
      assert 9..10          == Type.intersection(9..12,  1..10)
      assert 1..10          == Type.intersection(1..12,  1..10)
      assert 1..10          == Type.intersection(0..12,  1..10)
      assert 1..10          == Type.intersection(0..10,  1..10)
      assert 1..2           == Type.intersection(0..2,   1..10)
      assert 1              == Type.intersection(0..1,   1..10)
      assert builtin(:none) == Type.intersection(-1..0,  1..10)
    end

    test "with integers" do
      assert builtin(:none) == Type.intersection(1..10, -42)
      assert 47 == Type.intersection(0..255, 47)
      assert builtin(:none) == Type.intersection(1..10, 42)
    end

    test "with unions works as expected" do
      assert (1 <|> 9..10) == Type.intersection(1..10, (0..1 <|> 9..15))
      assert builtin(:none) == Type.intersection(1..10, (builtin(:atom) <|> builtin(:port)))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([-10..10, builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer)])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(1..10, target)
      end)
    end
  end
end
