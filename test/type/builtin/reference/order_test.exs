defmodule TypeTest.BuiltinReference.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "reference is bigger than atom and smaller types" do
    assert reference() > none()
    assert reference() > neg_integer()
    assert reference() > pos_integer()
    assert reference() > non_neg_integer()
    assert reference() > integer()
    assert reference() > float()
    assert reference() > atom()
  end

  test "reference is smaller than other types" do
    assert reference() < function()
    assert reference() < pid()
    assert reference() < port()
    assert reference() < tuple()
    assert reference() < map()
    assert reference() < maybe_improper_list()
    assert reference() < bitstring()
    assert reference() < any()
  end
end
