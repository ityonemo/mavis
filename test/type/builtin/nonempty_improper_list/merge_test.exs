defmodule TypeTest.BuiltinNonemptyImproperList.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "nonempty_improper_list merges with none" do
    assert {:merge, [nonempty_improper_list(any(), any())]} == Type.merge(nonempty_improper_list(any(), any()), none())
  end

  test "nonempty_improper_list merges with literal nonempty improper list" do
    assert {:merge, [nonempty_improper_list(any(), any())]} ==
      Type.merge(nonempty_improper_list(any(), any()), [47 | 47])
  end

  test "nonempty_improper_list does not merge with an empty list" do
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), [])
  end

  test "nonempty_improper_list doesn't merge with anything else" do
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), neg_integer())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), pos_integer())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), float())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), reference())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), function())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), port())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), pid())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), tuple())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), map())
    assert :nomerge == Type.merge(nonempty_improper_list(any(), any()), bitstring())
  end
end
