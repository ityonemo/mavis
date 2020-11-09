defmodule TypeTest.LiteralInteger.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "a negative integer" do
    test "is bigger than bottom" do
      assert -47 > builtin(:none)
    end

    test "is bigger than smaller numbers, and smaller ranges" do
      assert -47 > -50
      assert -47 > -100..-50
    end

    test "is smaller than that which it's a subtype" do
      assert -47 < -50..-47
      assert -47 < -50..-45
      assert -47 < -47..0
      assert -47 < builtin(:neg_integer)
      assert -47 < builtin(:integer)
    end

    test "is smaller than non negative numbers, number classes" do
      assert -47 < -42
      assert -47 < 0
      assert -47 < 47
      assert -47 < builtin(:non_neg_integer)
      assert -47 < builtin(:pos_integer)
    end

    test "is smaller than content outside its class" do
      assert -47 < builtin(:atom)  # test one thing out of its typegroup
      assert -47 < builtin(:any)   # test top
    end
  end

  describe "a positive integer" do
    test "is bigger than bottom" do
      assert 47 > builtin(:none)
    end

    test "is bigger than negative numbers, ranges, and classes" do
      assert 47 > -47
      assert 47 > 42
      assert 47 > -3..46
      assert 47 > builtin(:neg_integer)
    end

    test "is smaller than a union containing it" do
      assert 47 < -47 <|> 47
    end

    test "is smaller than that which it's a subtype of" do
      assert 47 < 42..47
      assert 47 < 42..50
      assert 47 < 47..50

      assert 47 < builtin(:pos_integer)
      assert 47 < builtin(:non_neg_integer)
    end

    test "is smaller than bigger numbers and ranges" do
      assert 47 < 50
      assert 47 < 50..100
    end

    test "is smaller than most types" do
      assert 47 < builtin(:atom)  # test one thing out of its typegroup
      assert 47 < builtin(:any)   # test top
    end
  end
end
