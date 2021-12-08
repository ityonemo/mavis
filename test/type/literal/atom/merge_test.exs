defmodule TypeTest.LiteralAtom.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "literal atom merges with none" do
    assert {:merge, [:atom]} == Type.merge(:atom, none())
  end

  test "literal atom merges with the same literal atom" do
    assert {:merge, [:atom]} == Type.merge(:atom, :atom)
  end

  test "literal atom does not merge with a different literal atom" do
    assert :nomerge == Type.merge(:atom, :foo)
  end

  test "literal atom merges with module" do
    assert {:merge, [module()]} == Type.merge(:atom, module())
  end

  test "well-formed node atoms merge with node" do
    assert {:merge, [type(node())]} == Type.merge(:foo@bar, type(node()))
  end

  test "literal atom merges with atom" do
    assert {:merge, [atom()]} == Type.merge(:atom, atom())
  end

  test "ill-formed node atoms don'tmerge with node" do
    assert :nomerge == Type.merge(:foo, type(node()))
  end

  test "literal atom doesn't merge with anything else" do
    assert :nomerge == Type.merge(:atom, neg_integer())
    assert :nomerge == Type.merge(:atom, pos_integer())
    assert :nomerge == Type.merge(:atom, float())
    assert :nomerge == Type.merge(:atom, reference())
    assert :nomerge == Type.merge(:atom, function())
    assert :nomerge == Type.merge(:atom, port())
    assert :nomerge == Type.merge(:atom, pid())
    assert :nomerge == Type.merge(:atom, tuple())
    assert :nomerge == Type.merge(:atom, map())
    assert :nomerge == Type.merge(:atom, nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(:atom, bitstring())
  end
end
