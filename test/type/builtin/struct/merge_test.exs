defmodule TypeTest.BuiltinStruct.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "struct merges with none" do
    assert {:merge, [struct()]} == Type.merge(struct(), none())
  end

  test "struct merges with any literal struct" do
    assert {:merge, [struct()]} == Type.merge(struct(), Type.literal(%Version{major: 0, minor: 2, patch: 0}))
  end

  test "struct merges with struct" do
    assert {:merge, [struct()]} == Type.merge(struct(), struct())
  end

  test "struct merges with map" do
    assert {:merge, [map()]} == Type.merge(struct(), map())
  end

  test "struct doesn't merge with anything else" do
    assert :nomerge == Type.merge(struct(), neg_integer())
    assert :nomerge == Type.merge(struct(), pos_integer())
    assert :nomerge == Type.merge(struct(), float())
    assert :nomerge == Type.merge(struct(), atom())
    assert :nomerge == Type.merge(struct(), reference())
    assert :nomerge == Type.merge(struct(), fun())
    assert :nomerge == Type.merge(struct(), port())
    assert :nomerge == Type.merge(struct(), pid())
    assert :nomerge == Type.merge(struct(), tuple())
    assert :nomerge == Type.merge(struct(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(struct(), bitstring())
  end
end
