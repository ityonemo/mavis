defmodule TypeTest.BuiltinPort.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "port merges with none" do
    assert {:merge, [port()]} == Type.merge(port(), none())
  end

  test "port merges with port" do
    assert {:merge, [port()]} == Type.merge(port(), port())
  end

  test "port doesn't merge with anything else" do
    assert :nomerge == Type.merge(port(), neg_integer())
    assert :nomerge == Type.merge(port(), pos_integer())
    assert :nomerge == Type.merge(port(), float())
    assert :nomerge == Type.merge(port(), atom())
    assert :nomerge == Type.merge(port(), reference())
    assert :nomerge == Type.merge(port(), function())
    assert :nomerge == Type.merge(port(), pid())
    assert :nomerge == Type.merge(port(), tuple())
    assert :nomerge == Type.merge(port(), map())
    assert :nomerge == Type.merge(port(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(port(), bitstring())
  end
end
