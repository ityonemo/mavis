defmodule TypeTest.LiteralRange.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the subtraction from a literal range" do
    test "of itself, integer and any is none" do
      assert none() == (-47..47) - any()
      assert none() == (-47..47) - integer()
      assert none() == (-47..47) - (-47..47)
    end

    test "of integer subsets" do
      # negative ranges
      assert none()  == (-47..-1) - neg_integer()
      assert -47..-1 == (-47..-1) - pos_integer()
      assert -47..-1 == (-47..-1) - non_neg_integer()

      # straddling ranges
      assert 0..47   == (-47..47) - neg_integer()
      assert 0       == (-1..0) - neg_integer()
      assert -47..0  == (-47..47) - pos_integer()
      assert 0       == (0..1) - pos_integer()
      assert -47..-1 == (-47..47) - non_neg_integer()
      assert -1      == (-1..0) - non_neg_integer()

      # positive ranges
      assert 1..47  == (1..47) - neg_integer()
      assert none() == (1..47) - pos_integer()
      assert none() == (1..47) - non_neg_integer()
    end

    test "of other ranges" do
      # disjoint left
      assert 1..10          == (1..10) - (11..12)
      # overlapping left
      assert 1..9           == (1..10) - (10..12)
      assert 1..8           == (1..10) - (9..12)
      assert 1              == (1..10) - (2..12)
      # internal left
      assert none()         == (1..10) - (1..12)
      # internal center
      assert none()         == (1..10) - (0..12)
      # internal right
      assert none()         == (1..10) - (0..10)
      # overlapping right
      assert 10             == (1..10) - (0..9)
      assert 3..10          == (1..10) - (0..2)
      assert 2..10          == (1..10) - (0..1)
      #disjoint right
      assert 1..10          == (1..10) - (-1..0)

      # internal subtractions
      assert 3..10          == (1..10) - (1..2)
      assert 1 <|> 4..10    == (1..10) - (2..3)
      assert 1..2 <|> 5..10 == (1..10) - (3..4)
      assert 1..7 <|> 10    == (1..10) - (8..9)
      assert 1..8           == (1..10) - (9..10)
    end

    test "of integers" do
      assert 1..10 == (1..10) - 47
      assert 1 <|> 3 == (1..3) - 2
      assert 0 <|> 2..47 == (0..47) - 1
      assert 0..46 <|> 48..255 == (0..255) - 47
      assert 0..253 <|> 255 == (0..255) - 254
    end

    test "of unions works as expected" do
      assert 2..8 == (1..10) - (0..1 <|> 9..15)
      assert 1 <|> 3 <|> 5 == (1..5) - (2 <|> 4)
      assert 1..10 == 1..10 - (atom() <|> port())
    end

    test "of all other types is none" do
      TypeTest.Targets.except([-10..10, pos_integer(), non_neg_integer(), integer()])
      |> Enum.each(fn target ->
        assert 1..10 == (1..10) - target
      end)
    end
  end
end
