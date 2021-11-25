defmodule TypeTest.BuiltinTuple.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "tuple is bigger pid types" do
    assert tuple() > none()
    assert tuple() > neg_integer()
    assert tuple() > pos_integer()
    assert tuple() > non_neg_integer()
    assert tuple() > integer()
    assert tuple() > float()
    assert tuple() > reference()
    assert tuple() > function()
    assert tuple() > port()
    assert tuple() > pid()
  end

  test "tuple is bigger than a literal tuple" do
    assert tuple() > Type.literal({:foo, :bar})
  end

  test "tuple is smaller than other types" do
    assert tuple() < map()
    assert tuple() < maybe_improper_list()
    assert tuple() < bitstring()
    assert tuple() < any()
  end
end
