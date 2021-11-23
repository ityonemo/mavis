defmodule TypeTest.BuiltinAtom.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "atom is bigger than none and number types" do
    assert atom() > none()
    assert atom() > neg_integer()
    assert atom() > pos_integer()
    assert atom() > non_neg_integer()
    assert atom() > integer()
    assert atom() > float()
  end

  test "atom is bigger than atom subtypes" do
    assert atom() > module()
    assert atom() > node()
  end

  test "atom is bigger than atom literals" do
    assert atom() > :foo
  end

  test "atom is smaller than other types" do
    assert atom() < reference()
    assert atom() < function()
    assert atom() < port()
    assert atom() < pid()
    assert atom() < tuple()
    assert atom() < map()
    assert atom() < maybe_improper_list()
    assert atom() < bitstring()
    assert atom() < any()
  end
end
