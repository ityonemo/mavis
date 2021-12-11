defmodule TypeTest.BuiltinFun.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order
  @moduletag :function

  import Type, only: :macros

  use Type.Operators

  test "fun is bigger than refs and smaller types" do
    assert fun() > none()
    assert fun() > neg_integer()
    assert fun() > pos_integer()
    assert fun() > non_neg_integer()
    assert fun() > integer()
    assert fun() > float()
    assert fun() > atom()
    assert fun() > reference()
  end

  test "fun is smaller than other types" do
    assert fun() < port()
    assert fun() < pid()
    assert fun() < tuple()
    assert fun() < map()
    assert fun() < maybe_improper_list()
    assert fun() < bitstring()
    assert fun() < any()
  end
end
