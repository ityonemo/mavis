defmodule TypeTest.BuiltinNonemptyMaybeImproperList.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "nonempty_maybe_improper_list merges with none" do
    assert {:merge, [nonempty_maybe_improper_list()]} == Type.merge(nonempty_maybe_improper_list(), none())
  end

  test "nonempty_maybe_improper_list merges with literal nonempty improper list" do
    assert {:merge, [nonempty_maybe_improper_list()]} ==
      Type.merge(nonempty_maybe_improper_list(), [47 | 47])
  end

  test "nonempty_maybe_improper_list does not merge with an empty list" do
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), [])
  end

  test "nonempty_maybe_improper_list doesn't merge with anything else" do
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), neg_integer())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), pos_integer())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), float())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), reference())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), function())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), port())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), pid())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), tuple())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), map())
    assert :nomerge == Type.merge(nonempty_maybe_improper_list(), bitstring())
  end
end
