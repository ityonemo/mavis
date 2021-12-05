defmodule TypeTest.BuiltinPid.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "pid merges with none" do
    assert {:merge, [pid()]} == Type.merge(pid(), none())
  end

  test "pid merges with pid" do
    assert {:merge, [pid()]} == Type.merge(pid(), pid())
  end

  test "pid doesn't merge with anything else" do
    assert :nomerge == Type.merge(pid(), neg_integer())
    assert :nomerge == Type.merge(pid(), pos_integer())
    assert :nomerge == Type.merge(pid(), float())
    assert :nomerge == Type.merge(pid(), atom())
    assert :nomerge == Type.merge(pid(), reference())
    assert :nomerge == Type.merge(pid(), function())
    assert :nomerge == Type.merge(pid(), port())
    assert :nomerge == Type.merge(pid(), tuple())
    assert :nomerge == Type.merge(pid(), map())
    assert :nomerge == Type.merge(pid(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(pid(), bitstring())
  end
end
