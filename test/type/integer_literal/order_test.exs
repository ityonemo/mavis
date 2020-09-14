defmodule TypeTest.IntegerLiteral.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "a negative integer" do
    test "is bigger than some types" do
      assert builtin(:none) < -47  # test bottom
      assert builtin(:integer) < -47
      assert builtin(:neg_integer) < -47
    end

    test "is smaller than most types" do
      assert -47 < builtin(:non_neg_integer)
      assert -47 < builtin(:pos_integer)
      assert -47 < builtin(:atom)  # test one thing out of its typegroup
      assert -47 < builtin(:any)   # test top
    end

    test "compares against ranges depending on the top value" do
      assert -42 > -100..-47
      assert -47 < 0..4
      assert -47 < -47..-42
    end

    test "internally respects standard erlang ordering internally" do
      assert -42 > -47
      assert -47 < 0
      assert -47 < 47
    end
  end

  describe "zero" do
    test "is bigger than some types" do
      assert builtin(:none) < 0  # test bottom
      assert builtin(:integer) < 0
      assert builtin(:neg_integer) < 0
      assert builtin(:non_neg_integer) < 0
    end

    test "is smaller than most types" do
      assert 0 < builtin(:pos_integer)
      assert 0 < builtin(:atom)  # test one thing out of its typegroup
      assert 0 < builtin(:any)   # test top
    end

    test "compares against ranges depending on the top value" do
      assert 0 > -100..-47
      assert 0 < 0..4
      assert 0 < 1..4
    end

    test "internally respects standard erlang ordering internally" do
      assert -47 < 0
      assert 0 < 47
    end
  end

  describe "a positive integer" do
    test "is bigger than some types" do
      assert builtin(:none) < 47  # test bottom
      assert builtin(:integer) < 47
      assert builtin(:neg_integer) < 47
      assert builtin(:non_neg_integer) < 47
      assert builtin(:pos_integer) < 47
    end

    test "is smaller than most types" do
      assert 47 < builtin(:atom)  # test one thing out of its typegroup
      assert 47 < builtin(:any)   # test top
    end

    test "compares against ranges depending on the top value" do
      assert 47 > 0..47
      assert 47 < 47..50
      assert 47 < 50..100
    end

    test "internally respects standard erlang ordering internally" do
      assert -47 < 47
      assert 0 < 47
      assert 47 < 50
    end
  end
end
