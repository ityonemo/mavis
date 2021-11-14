defmodule TypeTest.BuiltinBoolean.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "boolean is bigger than none and number types" do
    assert boolean() > none()
    assert boolean() > neg_integer()
    assert boolean() > pos_integer()
    assert boolean() > non_neg_integer()
    assert boolean() > integer()
    assert boolean() > float()
  end

  test "boolean is bigger than individual booleans" do
    assert boolean() > true
    assert boolean() > false
  end

  test "boolean is smaller than atom" do
    assert boolean() < atom()
  end

  test "boolean is smaller than the other types" do
    assert boolean() < reference()
    assert boolean() < function()
    assert boolean() < port()
    assert boolean() < pid()
    assert boolean() < tuple()
    assert boolean() < map()
    assert boolean() < maybe_improper_list()
    assert boolean() < binary()
    assert boolean() < any()
  end
end
