defmodule TypeTest.BuiltinMap.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge
  @moduletag :map

  import Type, only: :macros

  use Type.Operators

  test "map merges with none" do
    assert {:merge, [map()]} == Type.merge(map(), none())
  end

  test "map merges with any map type" do
    assert {:merge, [map()]} == Type.merge(map(), type(%{optional(float()) => atom()}))
  end

  test "map merges with any literal map" do
    assert {:merge, [map()]} == Type.merge(map(), Type.literal(%{"foo" => "bar"}))
  end

  test "map merges with map" do
    assert {:merge, [map()]} == Type.merge(map(), map())
  end

  test "map doesn't merge with anything else" do
    assert :nomerge == Type.merge(map(), neg_integer())
    assert :nomerge == Type.merge(map(), pos_integer())
    assert :nomerge == Type.merge(map(), float())
    assert :nomerge == Type.merge(map(), atom())
    assert :nomerge == Type.merge(map(), reference())
    assert :nomerge == Type.merge(map(), fun())
    assert :nomerge == Type.merge(map(), port())
    assert :nomerge == Type.merge(map(), pid())
    assert :nomerge == Type.merge(map(), tuple())
    assert :nomerge == Type.merge(map(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(map(), bitstring())
  end
end
