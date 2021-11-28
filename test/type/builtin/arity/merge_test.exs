defmodule TypeTest.BuiltinArity.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "arity merges with none" do
    assert {:merge, [arity()]} == Type.merge(arity(), none())
  end

  test "arity merges with literal integers in range" do
    assert {:merge, [arity()]} == Type.merge(arity(), 0)
    assert {:merge, [arity()]} == Type.merge(arity(), 1)
  end

  test "arity merges with literal ranges in range" do
    assert {:merge, [arity()]} == Type.merge(arity(), 1..10)
  end

  test "arity breaks into range when merged with a literal number outside" do
    assert {:merge, [-1..255]} == Type.merge(arity(), -1)
  end

  test "arity breaks into range when merged with a literal range outside" do
    assert {:merge, [-1..255]} == Type.merge(arity(), -1..10)
    assert {:merge, [-2..255]} == Type.merge(arity(), -2..-1)
  end

  test "arity merges with arity" do
    assert {:merge, [arity()]} == Type.merge(arity(), arity())
  end

  test "arity merges with arity integer supersets" do
    assert {:merge, [pos_integer(), 0]} == Type.merge(arity(), pos_integer())
  end

  test "arity doesn't merge with anything else" do
    assert :nomerge == Type.merge(arity(), neg_integer())
    assert :nomerge == Type.merge(arity(), float())
    assert :nomerge == Type.merge(arity(), reference())
    assert :nomerge == Type.merge(arity(), function())
    assert :nomerge == Type.merge(arity(), port())
    assert :nomerge == Type.merge(arity(), pid())
    assert :nomerge == Type.merge(arity(), tuple())
    assert :nomerge == Type.merge(arity(), map())
    assert :nomerge == Type.merge(arity(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(arity(), bitstring())
  end
end
