defmodule TypeTest.BuiltinFunction.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order
  @moduletag :function

  import Type, only: :macros

  use Type.Operators

  test "function is bigger than refs and smaller types" do
    assert function() > none()
    assert function() > neg_integer()
    assert function() > pos_integer()
    assert function() > non_neg_integer()
    assert function() > integer()
    assert function() > float()
    assert function() > atom()
    assert function() > reference()
  end

  test "function is smaller than other types" do
    assert function() < port()
    assert function() < pid()
    assert function() < tuple()
    assert function() < map()
    assert function() < maybe_improper_list()
    assert function() < bitstring()
    assert function() < any()
  end
end
