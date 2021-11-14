defmodule TypeTest.BuiltinChar.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "char is bigger than none and neg_integer types" do
    assert char() > none()
    assert char() > neg_integer()
  end

  test "char is bigger than smaller and internal numbers and internal ranges" do
    assert char() > -47
    assert char() > 255
    assert char() > 1..0x10_FFFF
  end

  test "char is smaller than all other integer types" do
    assert char() < pos_integer()
    assert char() < non_neg_integer()
    assert char() < integer()
  end

  test "char is smaller than all other types" do
    assert char() < float()
    assert char() < atom()
    assert char() < reference()
    assert char() < function()
    assert char() < port()
    assert char() < pid()
    assert char() < tuple()
    assert char() < map()
    assert char() < maybe_improper_list()
    assert char() < bitstring()
    assert char() < any()
  end
end
