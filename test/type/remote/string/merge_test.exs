defmodule TypeTest.RemoteString.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros
  alias Type.Bitstring

  use Type.Operators

  test "String.t/1 merges with none" do
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), none())
  end

  test "String.t/1 merges with literal binaries" do
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), "String.t/1")
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), "")
  end

  test "String.t/1 merges with String.t/1 subtypes" do
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), %Bitstring{unit: 16, unicode: true})
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), %Bitstring{size: 8, unit: 8, unicode: true})
  end

  test "String.t/1 merges with String.t/1 with a minimum length" do
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), %Bitstring{size: 8, unit: 16, unicode: true})
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), %Bitstring{size: 0, unit: 0, unicode: true})

    # note that a zero-length string type without unicode can still be merged:
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), type(<<_::0, _::_*0>>))
  end

  test "String.t/1 merges with String.t/1" do
    assert {:merge, [type(String.t())]} == Type.merge(type(String.t()), type(String.t()))
  end

  test "String.t/1 merges into bitstring and binary" do
    assert {:merge, [binary()]} == Type.merge(type(String.t()), binary())
    assert {:merge, [bitstring()]} == Type.merge(type(String.t()), bitstring())
  end

  test "String.t/1 doesn't merge against a different unit" do
    assert :nomerge == Type.merge(type(String.t()), type(<<_::_*3>>))
  end

  test "String.t/1 doesn't merge against the same unit, incompatible minsize" do
    assert :nomerge == Type.merge(type(String.t()), type(<<_::_*8, _::3>>))
  end

  test "String.t/1 doesn't merge with anything else" do
    assert :nomerge == Type.merge(type(String.t()), neg_integer())
    assert :nomerge == Type.merge(type(String.t()), pos_integer())
    assert :nomerge == Type.merge(type(String.t()), float())
    assert :nomerge == Type.merge(type(String.t()), atom())
    assert :nomerge == Type.merge(type(String.t()), reference())
    assert :nomerge == Type.merge(type(String.t()), function())
    assert :nomerge == Type.merge(type(String.t()), port())
    assert :nomerge == Type.merge(type(String.t()), pid())
    assert :nomerge == Type.merge(type(String.t()), tuple())
    assert :nomerge == Type.merge(type(String.t()), map())
    assert :nomerge == Type.merge(type(String.t()), nonempty_maybe_improper_list())
  end
end
