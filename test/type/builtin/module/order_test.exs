defmodule TypeTest.BuiltinAtom.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "module is bigger than none and number types" do
    assert module() > none()
    assert module() > neg_integer()
    assert module() > pos_integer()
    assert module() > non_neg_integer()
    assert module() > integer()
    assert module() > float()
  end

  test "module is smaller than atom, its parent" do
    assert module() < atom()
  end

  test "module is smaller than other types" do
    assert module() < reference()
    assert module() < function()
    assert module() < port()
    assert module() < pid()
    assert module() < tuple()
    assert module() < map()
    assert module() < maybe_improper_list()
    assert module() < bitstring()
    assert module() < any()
  end
end
