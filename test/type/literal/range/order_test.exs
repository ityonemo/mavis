defmodule TypeTest.LiteralRange.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "a negative range" do
    test "is bigger than bottom" do
      assert -47..-42 > none()
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
      assert -47..-42 < neg_integer()
      assert -47..-42 < integer()
    end

    test "is smaller than things bigger than it" do
      assert -47..-42 < -10
      assert -47..-42 < pos_integer()
      assert -47..-42 < non_neg_integer()
    end

    test "is smaller than things outside of integer" do
      assert -47..-42 < atom()
      assert -47..-42 < any()
    end
  end

  describe "a positive range" do
    test "is bigger than bottom" do
      assert 42..47 > none()
    end

    test "is bigger than numbers and ranges less than it" do
      assert 42..47 > neg_integer()
      assert 42..47 > 40
      assert 42..47 > -47..-42
    end

    test "is bigger than numbers and ranges inside of it" do
      assert 42..47 > 42
      assert 42..47 > 43..45
      assert 42..47 > 43..47
    end

    test "is smaller than a union containing it" do
      assert 42..47 < 0 <|> 42..47
    end

    test "is smaller than the classes, it is a subset of" do
      assert 42..47 < 0..47
      assert 42..47 < pos_integer()
      assert 42..47 < non_neg_integer()
      assert 42..47 < integer()
    end

    test "is smaller than things bigger than it" do
      assert 42..47 < 50
      assert 42..47 < 50..52
    end

    test "is smaller than things outside of integer" do
      assert 42..47 < atom()
      assert 42..47 < any()
    end
  end

end
