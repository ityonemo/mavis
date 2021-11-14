defmodule TypeTest.BuiltinBinary.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "binary is bigger than none and number types" do
    assert binary() > none()
    assert binary() > neg_integer()
    assert binary() > pos_integer()
    assert binary() > non_neg_integer()
    assert binary() > integer()
    assert binary() > float()
    assert binary() > atom()
    assert binary() > reference()
    assert binary() > function()
    assert binary() > port()
    assert binary() > pid()
    assert binary() > tuple()
    assert binary() > map()
    assert binary() > maybe_improper_list()
  end

  test "binary is bigger than String.t and wider binaries" do
    assert binary() > type(String.t())
    assert binary() > type(<<_::8, _::_*8>>)
    assert binary() > type(<<_::_*16>>)
  end

  test "binary is bigger than binary literals" do
    assert binary() > "foo"
  end

  test "binary is smaller than the generalized bitstring and any" do
    assert binary() < bitstring()
    assert binary() < any()
  end
end
