defmodule TypeTest.BuiltinTerm.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "term is bigger than all types" do
    assert term() > none()
    assert term() > neg_integer()
    assert term() > pos_integer()
    assert term() > non_neg_integer()
    assert term() > integer()
    assert term() > float()
    assert term() > atom()
    assert term() > reference()
    assert term() > function()
    assert term() > port()
    assert term() > pid()
    assert term() > tuple()
    assert term() > map()
    assert term() > maybe_improper_list()
    assert term() > bitstring()
  end
end
