defmodule TypeTest.BuiltinPid.NoneTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "none is smaller than all types" do
    assert none() < neg_integer()
    assert none() < pos_integer()
    assert none() < non_neg_integer()
    assert none() < integer()
    assert none() < float()
    assert none() < atom()
    assert none() < reference()
    assert none() < function()
    assert none() < port()
    assert none() < pid()
    assert none() < tuple()
    assert none() < map()
    assert none() < maybe_improper_list()
    assert none() < bitstring()
    assert none() < any()
  end
end
