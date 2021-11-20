defmodule TypeTest.BuiltinInteger.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "integer is bigger subsets of integer" do
    assert integer() > none()
    assert integer() > neg_integer()
    assert integer() > pos_integer()
    assert integer() > non_neg_integer()
  end

  test "integer is bigger than ranges" do
    assert integer() > -10..10
  end

  test "integer is bigger than an example" do
    assert integer() > 47
  end

  test "integer is smaller than other types" do
    assert integer() < float()
    assert integer() < atom()
    assert integer() < reference()
    assert integer() < port()
    assert integer() < pid()
    assert integer() < tuple()
    assert integer() < map()
    assert integer() < maybe_improper_list()
    assert integer() < bitstring()
    assert integer() < any()
  end
end
