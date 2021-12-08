defmodule TypeTest.BuiltinByte.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "byte merges with none" do
    assert {:merge, [byte()]} == Type.merge(byte(), none())
  end

  test "byte merges with literal integers in range" do
    assert {:merge, [byte()]} == Type.merge(byte(), 0)
    assert {:merge, [byte()]} == Type.merge(byte(), 1)
  end

  test "byte merges with literal ranges in range" do
    assert {:merge, [byte()]} == Type.merge(byte(), 1..10)
  end

  test "byte breaks into range when merged with a literal number outside" do
    assert {:merge, [-1..255]} == Type.merge(byte(), -1)
  end

  test "byte breaks into range when merged with a literal range outside" do
    assert {:merge, [-1..255]} == Type.merge(byte(), -1..10)
    assert {:merge, [-2..255]} == Type.merge(byte(), -2..-1)
  end

  test "byte merges with byte" do
    assert {:merge, [byte()]} == Type.merge(byte(), byte())
  end

  test "byte merges with byte integer supertypes" do
    assert {:merge, [pos_integer(), 0]} == Type.merge(byte(), pos_integer())
  end

  test "byte doesn't merge with anything else" do
    assert :nomerge == Type.merge(byte(), neg_integer())
    assert :nomerge == Type.merge(byte(), float())
    assert :nomerge == Type.merge(byte(), reference())
    assert :nomerge == Type.merge(byte(), function())
    assert :nomerge == Type.merge(byte(), port())
    assert :nomerge == Type.merge(byte(), pid())
    assert :nomerge == Type.merge(byte(), tuple())
    assert :nomerge == Type.merge(byte(), map())
    assert :nomerge == Type.merge(byte(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(byte(), bitstring())
  end
end
