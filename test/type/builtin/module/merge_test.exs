defmodule TypeTest.BuiltinModule.MergeTest do
  use ExUnit.Case, async: true

  @moduletag :merge

  import Type, only: :macros

  use Type.Operators

  test "module merges with none" do
    assert {:merge, [module()]} == Type.merge(module(), none())
  end

  test "module merges with any literal module" do
    assert {:merge, [module()]} == Type.merge(module(), String)
  end

  test "module merges with module" do
    assert {:merge, [module()]} == Type.merge(module(), module())
  end

  test "module merges to become atom" do
    assert {:merge, [atom()]} == Type.merge(module(), atom())
  end

  test "module doesn't merge with node" do
    assert :nomerge == Type.merge(module(), type(node()))
  end

  test "module doesn't merge with anything else" do
    assert :nomerge == Type.merge(module(), neg_integer())
    assert :nomerge == Type.merge(module(), pos_integer())
    assert :nomerge == Type.merge(module(), float())
    assert :nomerge == Type.merge(module(), reference())
    assert :nomerge == Type.merge(module(), fun())
    assert :nomerge == Type.merge(module(), port())
    assert :nomerge == Type.merge(module(), pid())
    assert :nomerge == Type.merge(module(), tuple())
    assert :nomerge == Type.merge(module(), map())
    assert :nomerge == Type.merge(module(), nonempty_maybe_improper_list())
    assert :nomerge == Type.merge(module(), bitstring())
  end
end
