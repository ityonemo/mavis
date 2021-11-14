defmodule TypeTest.BuiltinCharlist.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "charlist is bigger than none and neg_integer types" do
    assert charlist() > none()
    assert charlist() > neg_integer()
    assert charlist() > float()
    assert charlist() > atom()
    assert charlist() > reference()
    assert charlist() > function()
    assert charlist() > port()
    assert charlist() > pid()
    assert charlist() > tuple()
    assert charlist() > map()
  end

  test "charlist is bigger than list of -1s" do
    assert charlist() > list(-1)
  end

  test "charlist is bigger than any individual charlist'" do
    assert charlist() > [[47], 47]
  end

  test "charlist is smaller than list of binaries" do
    assert charlist() < list(binary())
  end

  test "charlist is smaller than iolist" do
    assert charlist() < iolist()
  end

  test "charlist is smaller than all other types" do
    assert charlist() < maybe_improper_list()
    assert charlist() < bitstring()
    assert charlist() < any()
  end
end
