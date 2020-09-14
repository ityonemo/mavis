defmodule TypeTest.RangeLiteral.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "a negative range" do
    test "is bigger than bottom" do
      assert -47..-42 > builtin(:none)
    end

    test "is bigger than a smaller integer" do
      assert -47..-42 > -50
    end

    test "is bigger than things inside of it" do
      assert -47..-42 > -43
      assert -47..-42 > -45..-43
      assert -47..-42 > -47..-43
    end

    test "is smaller than neg_integer and integer, which it is a subset of" do
      assert -47..-42 < -50..-42
      assert -47..-42 < -50..50
      assert -47..-42 < builtin(:neg_integer)
      assert -47..-42 < builtin(:integer)
    end

    test "is smaller than things bigger than it" do
      assert -47..-42 < -10
      assert -47..-42 < builtin(:pos_integer)
      assert -47..-42 < builtin(:non_neg_integer)
    end

    test "is smaller than things outside of integer" do
      assert -47..-42 < builtin(:atom)
      assert -47..-42 < builtin(:any)
    end
  end

  describe "a positive range" do
    test "is bigger than bottom" do
      assert 42..47 > builtin(:none)
    end

    test "is bigger than numbers and ranges less than it" do
      assert 42..47 > builtin(:neg_integer)
      assert 42..47 > 40
      assert 42..47 > -47..-42
    end

    test "is bigger than numbers and ranges inside of it" do
      assert 42..47 > 42
      assert 42..47 > 43..45
      assert 42..47 > 43..47
    end

    test "is smaller than the classes, it is a subset of" do
      assert 42..47 < 0..47
      assert 42..47 < builtin(:pos_integer)
      assert 42..47 < builtin(:non_neg_integer)
      assert 42..47 < builtin(:integer)
    end

    test "is smaller than things bigger than it" do
      assert 42..47 < 50
      assert 42..47 < 50..52
    end

    test "is smaller than things outside of integer" do
      assert 42..47 < builtin(:atom)
      assert 42..47 < builtin(:any)
    end
  end

end
