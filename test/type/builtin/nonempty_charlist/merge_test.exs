defmodule TypeTest.BuiltinNonemptyCharlist.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "nonempty_charlist merges with none" do
    assert {:merge, [nonempty_charlist()]} == Type.merge(nonempty_charlist(), none())
  end

  test "nonempty_charlist merges with literal list" do
    assert {:merge, [nonempty_charlist()]} == Type.merge(nonempty_charlist(), [47])
  end

  test "nonempty_charlist merges with a list of a superset" do
    assert {:merge, [type([pos_integer(), ...])]} = Type.merge(nonempty_charlist(), type([pos_integer(), ...]))
  end

  test "nonempty_charlist does not merge with a list out of range" do
    assert :nomerge == Type.merge(nonempty_charlist(), [-1])
  end

  test "nonempty_charlist does not merge with an empty list" do
    assert :nomerge == Type.merge(nonempty_charlist(), [])
  end

  test "nonempty_charlist doesn't merge with anything else" do
    assert :nomerge == Type.merge(nonempty_charlist(), neg_integer())
    assert :nomerge == Type.merge(nonempty_charlist(), pos_integer())
    assert :nomerge == Type.merge(nonempty_charlist(), float())
    assert :nomerge == Type.merge(nonempty_charlist(), reference())
    assert :nomerge == Type.merge(nonempty_charlist(), function())
    assert :nomerge == Type.merge(nonempty_charlist(), port())
    assert :nomerge == Type.merge(nonempty_charlist(), pid())
    assert :nomerge == Type.merge(nonempty_charlist(), tuple())
    assert :nomerge == Type.merge(nonempty_charlist(), map())
    assert :nomerge == Type.merge(nonempty_charlist(), bitstring())
  end
end
