defmodule TypeTest.BuiltinFun.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "fun merges with none" do
    assert {:merge, [fun()]} == Type.merge(fun(), none())
  end

  test "fun merges with fun example" do
    assert {:merge, [fun()]} == Type.merge(fun(), type(( -> any())))
  end

  test "fun merges with fun" do
    assert {:merge, [fun()]} == Type.merge(fun(), fun())
  end

  test "fun doesn't merge with anything else" do
    assert :nomerge == Type.merge(fun(), neg_integer())
    assert :nomerge == Type.merge(fun(), pos_integer())
    assert :nomerge == Type.merge(fun(), float())
    assert :nomerge == Type.merge(fun(), atom())
    assert :nomerge == Type.merge(fun(), reference())
    assert :nomerge == Type.merge(fun(), port())
    assert :nomerge == Type.merge(fun(), pid())
    assert :nomerge == Type.merge(fun(), tuple())
    assert :nomerge == Type.merge(fun(), map())
    assert :nomerge == Type.merge(fun(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(fun(), bitstring())
  end
end
