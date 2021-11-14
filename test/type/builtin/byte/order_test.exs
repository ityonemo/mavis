defmodule TypeTest.BuiltinByte.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "byte is bigger than none and neg_integer types" do
    assert byte() > none()
    assert byte() > neg_integer()
  end

  test "byte is bigger than smaller and internal numbers and internal ranges" do
    assert byte() > -47
    assert byte() > 255
    assert byte() > 1..255
  end

  test "byte is smaller than all other integer types" do
    assert byte() < pos_integer()
    assert byte() < non_neg_integer()
    assert byte() < integer()
  end

  test "byte is smaller than all other types" do
    assert byte() < float()
    assert byte() < atom()
    assert byte() < reference()
    assert byte() < function()
    assert byte() < port()
    assert byte() < pid()
    assert byte() < tuple()
    assert byte() < map()
    assert byte() < maybe_improper_list()
    assert byte() < bitstring()
    assert byte() < any()
  end
end
