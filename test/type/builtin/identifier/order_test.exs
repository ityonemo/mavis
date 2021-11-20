defmodule TypeTest.BuiltinIdentifier.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "identifier is bigger than ports and smaller types" do
    assert identifier() > none()
    assert identifier() > neg_integer()
    assert identifier() > pos_integer()
    assert identifier() > non_neg_integer()
    assert identifier() > integer()
    assert identifier() > float()
    assert identifier() > atom()
    assert identifier() > reference()
    assert identifier() > port()
    assert identifier() > pid()
  end

  test "identifier is smaller than other types" do
    assert identifier() < tuple()
    assert identifier() < map()
    assert identifier() < maybe_improper_list()
    assert identifier() < bitstring()
    assert identifier() < any()
  end
end
