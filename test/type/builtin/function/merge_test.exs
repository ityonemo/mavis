defmodule TypeTest.BuiltinFunction.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "function merges with none" do
    assert {:merge, [function()]} == Type.merge(function(), none())
  end

  test "function merges with function example" do
    assert {:merge, [function()]} == Type.merge(function(), type(( -> any())))
  end

  test "function merges with function" do
    assert {:merge, [function()]} == Type.merge(function(), function())
  end

  test "function doesn't merge with anything else" do
    assert :nomerge == Type.merge(function(), neg_integer())
    assert :nomerge == Type.merge(function(), pos_integer())
    assert :nomerge == Type.merge(function(), pos_integer())
    assert :nomerge == Type.merge(function(), atom())
    assert :nomerge == Type.merge(function(), reference())
    assert :nomerge == Type.merge(function(), function())
    assert :nomerge == Type.merge(function(), port())
    assert :nomerge == Type.merge(function(), pid())
    assert :nomerge == Type.merge(function(), tuple())
    assert :nomerge == Type.merge(function(), map())
    assert :nomerge == Type.merge(function(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(function(), bitstring())
  end
end
