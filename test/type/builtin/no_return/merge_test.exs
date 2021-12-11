defmodule TypeTest.BuiltinNoReturn.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "no_return merges with everything else" do
    assert {:merge, [none()]} == Type.merge(no_return(), none())
    assert {:merge, [neg_integer()]} == Type.merge(no_return(), neg_integer())
    assert {:merge, [pos_integer()]} == Type.merge(no_return(), pos_integer())
    assert {:merge, [float()]} == Type.merge(no_return(), float())
    assert {:merge, [reference()]} == Type.merge(no_return(), reference())
    assert {:merge, [function()]} == Type.merge(no_return(), function())
    assert {:merge, [port()]} == Type.merge(no_return(), port())
    assert {:merge, [pid()]} == Type.merge(no_return(), pid())
    assert {:merge, [tuple()]} == Type.merge(no_return(), tuple())
    assert {:merge, [map()]} == Type.merge(no_return(), map())
    assert {:merge, [nonempty_maybe_improper_list()]} == Type.merge(no_return(), nonempty_maybe_improper_list())
    assert {:merge, [bitstring()]} == Type.merge(no_return(), bitstring())
  end
end
