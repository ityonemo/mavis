defmodule TypeTest.BuiltinNonNegInteger.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "non_neg_integer is bigger than other subsets of integer" do
    assert non_neg_integer() > none()
    assert non_neg_integer() > neg_integer()
    assert non_neg_integer() > pos_integer()
  end

  test "non_neg_integer is bigger than positive ranges" do
    assert non_neg_integer() > 1..10
  end

  test "non_neg_integer is bigger than an example" do
    assert non_neg_integer() > 47
  end

  test "non_neg_integer is smaller than other types" do
    assert non_neg_integer() < integer()
    assert non_neg_integer() < float()
    assert non_neg_integer() < atom()
    assert non_neg_integer() < reference()
    assert non_neg_integer() < port()
    assert non_neg_integer() < pid()
    assert non_neg_integer() < tuple()
    assert non_neg_integer() < map()
    assert non_neg_integer() < maybe_improper_list()
    assert non_neg_integer() < bitstring()
    assert non_neg_integer() < any()
  end
end
