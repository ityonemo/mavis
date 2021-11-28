defmodule TypeTest.BuiltinChar.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "char merges with none" do
    assert {:merge, [char()]} == Type.merge(char(), none())
  end

  test "char merges with literal integers in range" do
    assert {:merge, [char()]} == Type.merge(char(), 0)
    assert {:merge, [char()]} == Type.merge(char(), 1)
  end

  test "char merges with literal ranges in range" do
    assert {:merge, [char()]} == Type.merge(char(), 1..10)
  end

  test "char breaks into range when merged with a literal number outside" do
    assert {:merge, [-1..0x10_FFFF]} == Type.merge(char(), -1)
  end

  test "char breaks into range when merged with a literal range outside" do
    assert {:merge, [-1..0x10_FFFF]} == Type.merge(char(), -1..10)
    assert {:merge, [-2..0x10_FFFF]} == Type.merge(char(), -2..-1)
  end

  test "char merges with char" do
    assert {:merge, [char()]} == Type.merge(char(), char())
  end

  test "char merges with char integer supersets" do
    assert {:merge, [pos_integer(), 0]} == Type.merge(char(), pos_integer())
  end

  test "char doesn't merge with anything else" do
    assert :nomerge == Type.merge(char(), neg_integer())
    assert :nomerge == Type.merge(char(), float())
    assert :nomerge == Type.merge(char(), reference())
    assert :nomerge == Type.merge(char(), function())
    assert :nomerge == Type.merge(char(), port())
    assert :nomerge == Type.merge(char(), pid())
    assert :nomerge == Type.merge(char(), tuple())
    assert :nomerge == Type.merge(char(), map())
    assert :nomerge == Type.merge(char(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(char(), bitstring())
  end
end
