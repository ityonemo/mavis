defmodule TypeTest.BuiltinNonemptyList.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "nonempty_list merges with none" do
    assert {:merge, [nonempty_list(any())]} == Type.merge(nonempty_list(any()), none())
  end

  test "nonempty_list merges with literal nonempty list" do
    assert {:merge, [nonempty_list(any())]} ==
      Type.merge(nonempty_list(any()), [47, 47])
  end

  test "nonempty_list does not merge with literal nonempty improper list" do
    assert :nomerge == Type.merge(nonempty_list(any()), [47 | 47])
  end

  test "nonempty_list does not merge with an empty list" do
    assert :nomerge == Type.merge(nonempty_list(any()), [])
  end

  test "nonempty_list doesn't merge with anything else" do
    assert :nomerge == Type.merge(nonempty_list(any()), neg_integer())
    assert :nomerge == Type.merge(nonempty_list(any()), pos_integer())
    assert :nomerge == Type.merge(nonempty_list(any()), float())
    assert :nomerge == Type.merge(nonempty_list(any()), reference())
    assert :nomerge == Type.merge(nonempty_list(any()), function())
    assert :nomerge == Type.merge(nonempty_list(any()), port())
    assert :nomerge == Type.merge(nonempty_list(any()), pid())
    assert :nomerge == Type.merge(nonempty_list(any()), tuple())
    assert :nomerge == Type.merge(nonempty_list(any()), map())
    assert :nomerge == Type.merge(nonempty_list(any()), bitstring())
  end
end
