defmodule TypeTest.BuiltinNegInteger.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "neg_integer merges with none" do
    assert {:merge, [neg_integer()]} == Type.merge(neg_integer(), none())
  end

  test "neg_integer merges with literal integers in range" do
    assert {:merge, [neg_integer()]} == Type.merge(neg_integer(), -10)
  end

  test "neg_integer merges with literal ranges in range" do
    assert {:merge, [neg_integer()]} == Type.merge(neg_integer(), -47..-10)
  end

  test "neg_integer adds zero when merged with a range topping out at zero" do
    assert {:merge, [0, neg_integer()]} == Type.merge(neg_integer(), -47..0)
  end

  test "neg_integer breaks upper range when merged with a range topping out at positive number" do
    assert {:merge, [0..47, neg_integer()]} == Type.merge(neg_integer(), -47..47)
  end
  test "neg_integer merges with neg_integer" do
    assert {:merge, [neg_integer()]} == Type.merge(neg_integer(), neg_integer())
  end

  test "neg_integer does not merge with 0 or positive integer or negative float or zero or positive range" do
    assert :nomerge == Type.merge(neg_integer(), 0)
    assert :nomerge == Type.merge(neg_integer(), 42)
    assert :nomerge == Type.merge(neg_integer(), 0..10)
    assert :nomerge == Type.merge(neg_integer(), 1..10)
  end

  test "neg_integer doesn't merge with anything else" do
    assert :nomerge == Type.merge(neg_integer(), pos_integer())
    assert :nomerge == Type.merge(neg_integer(), float())
    assert :nomerge == Type.merge(neg_integer(), reference())
    assert :nomerge == Type.merge(neg_integer(), function())
    assert :nomerge == Type.merge(neg_integer(), port())
    assert :nomerge == Type.merge(neg_integer(), pid())
    assert :nomerge == Type.merge(neg_integer(), tuple())
    assert :nomerge == Type.merge(neg_integer(), map())
    assert :nomerge == Type.merge(neg_integer(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(neg_integer(), bitstring())
  end
end
