defmodule TypeTest.BuiltinFloat.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "float merges with none" do
    assert {:merge, [float()]} == Type.merge(float(), none())
  end

  test "float merges with literal float" do
    assert {:merge, [float()]} == Type.merge(float(), 47.0)
  end

  test "float merges with float" do
    assert {:merge, [float()]} == Type.merge(float(), float())
  end

  test "float doesn't merge with anything else" do
    assert :nomerge == Type.merge(float(), neg_integer())
    assert :nomerge == Type.merge(float(), pos_integer())
    assert :nomerge == Type.merge(float(), atom())
    assert :nomerge == Type.merge(float(), reference())
    assert :nomerge == Type.merge(float(), function())
    assert :nomerge == Type.merge(float(), port())
    assert :nomerge == Type.merge(float(), pid())
    assert :nomerge == Type.merge(float(), tuple())
    assert :nomerge == Type.merge(float(), map())
    assert :nomerge == Type.merge(float(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(float(), bitstring())
  end
end
