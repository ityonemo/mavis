defmodule TypeTest.BuiltinNegInteger.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "neg_integer is bigger subsets of neg_integer" do
    assert neg_integer() > none()
    assert neg_integer() > neg_integer()
    assert neg_integer() > pos_integer()
    assert neg_integer() > non_neg_integer()
  end

  test "neg_integer is bigger than negative ranges" do
    assert neg_integer() > -10..-1
  end

  test "neg_integer is bigger than an example" do
    assert neg_integer() > -47
  end

  test "neg_integer is smaller than 0" do
    assert neg_integer() < 0
  end

  test "neg_integer is smaller than other types" do
    assert neg_integer() < float()
    assert neg_integer() < atom()
    assert neg_integer() < reference()
    assert neg_integer() < port()
    assert neg_integer() < pid()
    assert neg_integer() < tuple()
    assert neg_integer() < map()
    assert neg_integer() < maybe_improper_list()
    assert neg_integer() < bitstring()
    assert neg_integer() < any()
  end
end
