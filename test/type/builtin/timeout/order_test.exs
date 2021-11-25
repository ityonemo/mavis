defmodule TypeTest.BuiltinTimeout.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "timeout is bigger subsets of timeout" do
    assert timeout() > none()
    assert timeout() > neg_integer()
    assert timeout() > pos_integer()
    assert timeout() > non_neg_integer()
    assert timeout() > integer()
    assert timeout() > float()
  end

  test "timeout is bigger than ranges" do
    assert timeout() > 1..10
  end

  test "timeout is bigger than an example" do
    assert timeout() > 47
    assert timeout() > :infinity
  end

  test "timeout is smaller than other types" do
    assert timeout() < atom()
    assert timeout() < reference()
    assert timeout() < port()
    assert timeout() < pid()
    assert timeout() < tuple()
    assert timeout() < map()
    assert timeout() < maybe_improper_list()
    assert timeout() < bitstring()
    assert timeout() < any()
  end
end
