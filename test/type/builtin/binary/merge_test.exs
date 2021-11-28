defmodule TypeTest.BuiltinBinary.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "binary merges with none" do
    assert {:merge, [binary()]} == Type.merge(binary(), none())
  end

  test "binary merges with literal binaries" do
    assert {:merge, [binary()]} == Type.merge(binary(), "binary")
  end

  test "binary merges with binary subsets" do
    assert {:merge, [binary()]} == Type.merge(binary(), %Type.Bitstring{unit: 8, unicode: true})
    assert {:merge, [binary()]} == Type.merge(binary(), type(String.t()))
    assert {:merge, [binary()]} == Type.merge(binary(), type(<<_::_*16>>))
  end

  test "binary merges with binary with a minimum length" do
    assert {:merge, [binary()]} == Type.merge(binary(), type(<<_::_*8, _::16>>))
  end

  test "binary merges with binary" do
    assert {:merge, [binary()]} == Type.merge(binary(), binary())
  end

  test "binary merges into bitstring" do
    assert {:merge, [bitstring()]} == Type.merge(binary(), bitstring())
  end

  test "binary doesn't merge against a different unit" do
    assert :nomerge == Type.merge(binary(), type(<<_::_*3>>))
  end

  test "binary doesn't merge against the same unit, incompatible minsize" do
    assert :nomerge == Type.merge(binary(), type(<<_::_*8, _::3>>))
  end

  test "binary doesn't merge with anything else" do
    assert :nomerge == Type.merge(binary(), neg_integer())
    assert :nomerge == Type.merge(binary(), pos_integer())
    assert :nomerge == Type.merge(binary(), float())
    assert :nomerge == Type.merge(binary(), atom())
    assert :nomerge == Type.merge(binary(), reference())
    assert :nomerge == Type.merge(binary(), function())
    assert :nomerge == Type.merge(binary(), port())
    assert :nomerge == Type.merge(binary(), pid())
    assert :nomerge == Type.merge(binary(), tuple())
    assert :nomerge == Type.merge(binary(), map())
    assert :nomerge == Type.merge(binary(), nonempty_maybe_improper_list())
  end
end
