defmodule TypeTest.BuiltinBitstring.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "bitstring is bigger than none and number types" do
    assert bitstring() > none()
    assert bitstring() > neg_integer()
    assert bitstring() > pos_integer()
    assert bitstring() > non_neg_integer()
    assert bitstring() > integer()
    assert bitstring() > float()
    assert bitstring() > atom()
    assert bitstring() > reference()
    assert bitstring() > function()
    assert bitstring() > port()
    assert bitstring() > pid()
    assert bitstring() > tuple()
    assert bitstring() > map()
    assert bitstring() > maybe_improper_list()
  end

  test "bitstring is bigger than binaries" do
    assert bitstring() > type(String.t())
    assert bitstring() > type(<<_::8, _::_*1>>)
    assert bitstring() > binary()
  end

  test "bitstring is bigger than binary and bitstring literals" do
    assert bitstring() > "foo"
    assert bitstring() > <<7::3>>
  end

  test "bitstring is smaller than the generalized bitstring and any" do
    assert bitstring() < any()
  end
end
