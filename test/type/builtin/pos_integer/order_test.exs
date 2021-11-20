defmodule TypeTest.BuiltinPosInteger.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "pos_integer is bigger than neg_integer" do
    assert pos_integer() > none()
    assert pos_integer() > neg_integer()
  end


  test "pos_integer is bigger than positive ranges" do
    assert pos_integer() > 1..10
  end

  test "pos_integer is bigger than an example" do
    assert pos_integer() > 47
  end

  test "pos_integer is smaller than other types" do
    assert pos_integer() < non_neg_integer()
    assert pos_integer() < integer()
    assert pos_integer() < float()
    assert pos_integer() < atom()
    assert pos_integer() < reference()
    assert pos_integer() < port()
    assert pos_integer() < pid()
    assert pos_integer() < tuple()
    assert pos_integer() < map()
    assert pos_integer() < maybe_improper_list()
    assert pos_integer() < bitstring()
    assert pos_integer() < any()
  end
end
