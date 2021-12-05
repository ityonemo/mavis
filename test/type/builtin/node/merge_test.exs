defmodule TypeTest.BuiltinNode.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "node merges with none" do
    assert {:merge, [type(node())]} == Type.merge(type(node()), none())
  end

  test "node merges with any literal node" do
    assert {:merge, [type(node())]} == Type.merge(type(node()), :foo@bar)
  end

  test "node merges with node" do
    assert {:merge, [type(node())]} == Type.merge(type(node()), type(node()))
  end

  test "node merges to become atom" do
    assert {:merge, [atom()]} == Type.merge(type(node()), atom())
  end

  test "node doesn't merge with a non-node form atom" do
    assert :nomerge == Type.merge(type(node()), :bar)
  end

  test "node doesn't merge with anything else" do
    assert :nomerge == Type.merge(type(node()), neg_integer())
    assert :nomerge == Type.merge(type(node()), pos_integer())
    assert :nomerge == Type.merge(type(node()), float())
    assert :nomerge == Type.merge(type(node()), reference())
    assert :nomerge == Type.merge(type(node()), fun())
    assert :nomerge == Type.merge(type(node()), port())
    assert :nomerge == Type.merge(type(node()), pid())
    assert :nomerge == Type.merge(type(node()), tuple())
    assert :nomerge == Type.merge(type(node()), map())
    assert :nomerge == Type.merge(type(node()), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(type(node()), bitstring())
  end
end
