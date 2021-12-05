defmodule TypeTest.BuiltinNoReturn.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "no_return merges with everything else" do
    assert none() == Type.merge(no_return(), none())
    assert neg_integer() == Type.merge(no_return(), neg_integer())
    assert pos_integer() == Type.merge(no_return(), pos_integer())
    assert float() == Type.merge(no_return(), float())
    assert reference() == Type.merge(no_return(), reference())
    assert function() == Type.merge(no_return(), function())
    assert port() == Type.merge(no_return(), port())
    assert pid() == Type.merge(no_return(), pid())
    assert tuple() == Type.merge(no_return(), tuple())
    assert map() == Type.merge(no_return(), map())
    assert nonempty_maybe_improper_list() == Type.merge(no_return(), nonempty_maybe_improper_list())
    assert bitstring() == Type.merge(no_return(), bitstring())
  end
end
