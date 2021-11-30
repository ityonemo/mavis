defmodule TypeTest.BuiltinBitstring.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "bitstring merges with none" do
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), none())
  end

  test "bitstring merges with literal binaries and bitstrings" do
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), "bitstring")
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), <<7::7>>)
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), "")
  end

  test "bitstring merges with bitstring subtypes" do
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), %Type.Bitstring{unit: 16, unicode: true})
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), type(String.t()))
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), binary())
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), type(<<_::_*3>>))
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), type(<<>>))
  end

  test "bitstring merges with bitstring with a minimum length" do
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), type(<<_::_*3, _::3>>))
  end

  test "bitstring merges with bitstring" do
    assert {:merge, [bitstring()]} == Type.merge(bitstring(), bitstring())
  end

  test "bitstring doesn't merge with anything else" do
    assert :nomerge == Type.merge(bitstring(), neg_integer())
    assert :nomerge == Type.merge(bitstring(), pos_integer())
    assert :nomerge == Type.merge(bitstring(), float())
    assert :nomerge == Type.merge(bitstring(), atom())
    assert :nomerge == Type.merge(bitstring(), reference())
    assert :nomerge == Type.merge(bitstring(), function())
    assert :nomerge == Type.merge(bitstring(), port())
    assert :nomerge == Type.merge(bitstring(), pid())
    assert :nomerge == Type.merge(bitstring(), tuple())
    assert :nomerge == Type.merge(bitstring(), map())
    assert :nomerge == Type.merge(bitstring(), nonempty_maybe_improper_list())
  end
end
