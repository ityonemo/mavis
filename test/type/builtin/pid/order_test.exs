defmodule TypeTest.BuiltinPid.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "pid is bigger than function and smaller types" do
    assert pid() > none()
    assert pid() > neg_integer()
    assert pid() > pos_integer()
    assert pid() > non_neg_integer()
    assert pid() > integer()
    assert pid() > float()
    assert pid() > atom()
    assert pid() > reference()
    assert pid() > function()
    assert pid() > port()
  end

  test "pid is smaller than other types" do
    assert pid() < tuple()
    assert pid() < map()
    assert pid() < maybe_improper_list()
    assert pid() < bitstring()
    assert pid() < any()
  end
end
