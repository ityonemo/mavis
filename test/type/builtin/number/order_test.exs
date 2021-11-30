defmodule TypeTest.BuiltinNumber.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "number is bigger subtypes of number" do
    assert number() > none()
    assert number() > neg_integer()
    assert number() > pos_integer()
    assert number() > non_neg_integer()
    assert number() > integer()
    assert number() > float()
  end

  test "number is bigger than ranges" do
    assert number() > -10..10
  end

  test "number is bigger than an example" do
    assert number() > 47
    assert number() > 47.0
  end

  test "number is smaller than other types" do
    assert number() < atom()
    assert number() < reference()
    assert number() < port()
    assert number() < pid()
    assert number() < tuple()
    assert number() < map()
    assert number() < maybe_improper_list()
    assert number() < bitstring()
    assert number() < any()
  end
end
