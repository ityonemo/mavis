defmodule TypeTest.BuiltinAny.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "any is bigger than all types" do
    assert any() > none()
    assert any() > neg_integer()
    assert any() > pos_integer()
    assert any() > non_neg_integer()
    assert any() > integer()
    assert any() > float()
    assert any() > atom()
    assert any() > reference()
    assert any() > function()
    assert any() > port()
    assert any() > pid()
    assert any() > tuple()
    assert any() > map()
    assert any() > maybe_improper_list()
    assert any() > bitstring()
  end
end
