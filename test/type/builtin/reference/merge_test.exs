defmodule TypeTest.BuiltinReference.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "reference merges with none" do
    assert {:merge, [reference()]} == Type.merge(reference(), none())
  end

  test "reference merges with reference" do
    assert {:merge, [reference()]} == Type.merge(reference(), reference())
  end

  test "reference doesn't merge with anything else" do
    assert :nomerge == Type.merge(reference(), neg_integer())
    assert :nomerge == Type.merge(reference(), pos_integer())
    assert :nomerge == Type.merge(reference(), float())
    assert :nomerge == Type.merge(reference(), atom())
    assert :nomerge == Type.merge(reference(), function())
    assert :nomerge == Type.merge(reference(), pid())
    assert :nomerge == Type.merge(reference(), port())
    assert :nomerge == Type.merge(reference(), tuple())
    assert :nomerge == Type.merge(reference(), map())
    assert :nomerge == Type.merge(reference(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(reference(), bitstring())
  end
end
