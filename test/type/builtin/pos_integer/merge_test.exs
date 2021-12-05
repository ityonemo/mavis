defmodule TypeTest.BuiltinPosInteger.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "pos_integer merges with none" do
    assert {:merge, [pos_integer()]} == Type.merge(pos_integer(), none())
  end

  test "pos_integer merges with literal integers in range" do
    assert {:merge, [pos_integer()]} == Type.merge(pos_integer(), 10)
  end

  test "pos_integer merges with literal ranges in range" do
    assert {:merge, [pos_integer()]} == Type.merge(pos_integer(), 10..-47)
  end

  test "pos_integer adds zero when merged with a range topping out at zero" do
    assert {:merge, [pos_integer(), 0]} == Type.merge(pos_integer(), 0..47)
  end

  test "pos_integer breaks upper range when merged with a range topping out at positive number" do
    assert {:merge, [pos_integer(), -47..0]} == Type.merge(pos_integer(), -47..47)
  end

  test "pos_integer merges with pos_integer" do
    assert {:merge, [pos_integer()]} == Type.merge(pos_integer(), pos_integer())
  end

  test "pos_integer does not merge with 0 or positive integer or negative float or zero or positive range" do
    assert :nomerge == Type.merge(pos_integer(), 0)
    assert :nomerge == Type.merge(pos_integer(), -42)
    assert :nomerge == Type.merge(pos_integer(), -10..0)
    assert :nomerge == Type.merge(pos_integer(), -10..-1)
  end

  test "pos_integer doesn't merge with anything else" do
    assert :nomerge == Type.merge(pos_integer(), neg_integer())
    assert :nomerge == Type.merge(pos_integer(), float())
    assert :nomerge == Type.merge(pos_integer(), reference())
    assert :nomerge == Type.merge(pos_integer(), function())
    assert :nomerge == Type.merge(pos_integer(), port())
    assert :nomerge == Type.merge(pos_integer(), pid())
    assert :nomerge == Type.merge(pos_integer(), tuple())
    assert :nomerge == Type.merge(pos_integer(), map())
    assert :nomerge == Type.merge(pos_integer(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(pos_integer(), bitstring())
  end
end
