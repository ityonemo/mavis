defmodule TypeTest.BuiltinPid.NoReturnTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "no_return is smaller than all types" do
    assert no_return() < neg_integer()
    assert no_return() < pos_integer()
    assert no_return() < non_neg_integer()
    assert no_return() < integer()
    assert no_return() < float()
    assert no_return() < atom()
    assert no_return() < reference()
    assert no_return() < function()
    assert no_return() < port()
    assert no_return() < pid()
    assert no_return() < tuple()
    assert no_return() < map()
    assert no_return() < maybe_improper_list()
    assert no_return() < bitstring()
    assert no_return() < any()
  end
end
