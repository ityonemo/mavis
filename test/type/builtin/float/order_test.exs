defmodule TypeTest.BuiltinFloat.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "float is bigger than none and number types" do
    assert float() > none()
    assert float() > neg_integer()
    assert float() > pos_integer()
    assert float() > non_neg_integer()
    assert float() > integer()
  end

  test "float is bigger than float literals" do
    assert float() > 47.0
  end

  test "float is smaller than other types" do
    assert float() < atom()
    assert float() < reference()
    assert float() < function()
    assert float() < port()
    assert float() < pid()
    assert float() < tuple()
    assert float() < map()
    assert float() < maybe_improper_list()
    assert float() < bitstring()
    assert float() < any()
  end
end
