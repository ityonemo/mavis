defmodule TypeTest.BuiltinArity.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "arity is bigger than none and neg_integer types" do
    assert arity() > none()
    assert arity() > neg_integer()
  end

  test "arity is bigger than smaller and internal numbers and internal ranges" do
    assert arity() > -47
    assert arity() > 255
    assert arity() > 1..255
  end

  test "arity is smaller than all other integer types" do
    assert arity() < pos_integer()
    assert arity() < non_neg_integer()
    assert arity() < integer()
  end

  test "arity is smaller than all other types" do
    assert arity() < float()
    assert arity() < atom()
    assert arity() < reference()
    assert arity() < function()
    assert arity() < port()
    assert arity() < pid()
    assert arity() < tuple()
    assert arity() < map()
    assert arity() < maybe_improper_list()
    assert arity() < bitstring()
    assert arity() < any()
  end
end
