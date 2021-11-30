defmodule TypeTest.BuiltinIolist.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "iolist merges with none" do
    assert {:merge, [iolist()]} == Type.merge(iolist(), none())
  end

  test "iolist merges with iolist parts" do
    assert {:merge, [iolist()]} == Type.merge(iolist(), [])
    assert {:merge, [iolist()]} == Type.merge(iolist(), %Type.List{type: binary(), final: []})
    assert {:merge, [iolist()]} == Type.merge(iolist(), %Type.List{type: iolist(), final: []})
  end

  test "iolist merges with any literal iolist" do
    assert {:merge, [iolist()]} == Type.merge(iolist(), ["foo"])
    assert {:merge, [iolist()]} == Type.merge(iolist(), ["foo" | "bar"])
  end

  test "iolist merges with iolist" do
    assert {:merge, [iolist()]} == Type.merge(iolist(), iolist())
  end

  test "iolist doesn't merge with anything else" do
    assert :nomerge == Type.merge(iolist(), neg_integer())
    assert :nomerge == Type.merge(iolist(), pos_integer())
    assert :nomerge == Type.merge(iolist(), float())
    assert :nomerge == Type.merge(iolist(), atom())
    assert :nomerge == Type.merge(iolist(), reference())
    assert :nomerge == Type.merge(iolist(), fun())
    assert :nomerge == Type.merge(iolist(), port())
    assert :nomerge == Type.merge(iolist(), pid())
    assert :nomerge == Type.merge(iolist(), tuple())
    assert :nomerge == Type.merge(iolist(), map())
    assert :nomerge == Type.merge(iolist(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(iolist(), bitstring())
  end
end
