defmodule TypeTest.BuiltinTuple.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "tuple merges with none" do
    assert {:merge, [tuple()]} == Type.merge(tuple(), none())
  end

  test "tuple merges with any literal tuple" do
    assert {:merge, [tuple()]} == Type.merge(tuple(), Type.literal({1, 2, 3}))
  end

  test "tuple merges with tuple" do
    assert {:merge, [tuple()]} == Type.merge(tuple(), tuple())
  end

  test "tuple doesn't merge with anything else" do
    assert :nomerge == Type.merge(tuple(), neg_integer())
    assert :nomerge == Type.merge(tuple(), pos_integer())
    assert :nomerge == Type.merge(tuple(), float())
    assert :nomerge == Type.merge(tuple(), atom())
    assert :nomerge == Type.merge(tuple(), reference())
    assert :nomerge == Type.merge(tuple(), fun())
    assert :nomerge == Type.merge(tuple(), port())
    assert :nomerge == Type.merge(tuple(), pid())
    assert :nomerge == Type.merge(tuple(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(tuple(), bitstring())
  end
end
