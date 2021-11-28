defmodule TypeTest.BuiltinAtom.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "atom merges with none" do
    assert {:merge, atom()} == Type.merge(atom(), none())
  end

  test "atom merges with literal atoms" do
    assert {:merge, atom()} == Type.merge(atom(), :atom)
  end

  test "atom merges with atom subsets" do
    assert {:merge, atom()} == Type.merge(atom(), module())
    assert {:merge, atom()} == Type.merge(atom(), type(node()))
  end

  test "atom merges with atom" do
    assert {:merge, atom()} == Type.merge(atom(), atom())
  end

  test "atom doesn't merge with anything else" do
    assert :nomerge == Type.merge(atom(), neg_integer())
    assert :nomerge == Type.merge(atom(), pos_integer())
    assert :nomerge == Type.merge(atom(), float())
    assert :nomerge == Type.merge(atom(), reference())
    assert :nomerge == Type.merge(atom(), function())
    assert :nomerge == Type.merge(atom(), port())
    assert :nomerge == Type.merge(atom(), pid())
    assert :nomerge == Type.merge(atom(), tuple())
    assert :nomerge == Type.merge(atom(), map())
    assert :nomerge == Type.merge(atom(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(atom(), bitstring())
  end
end
