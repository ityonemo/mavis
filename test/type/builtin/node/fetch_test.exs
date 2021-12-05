defmodule TypeTest.BuiltinNode.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule ModuleChild do  # note this can't be Module because it forces a Module alias.
    @type node_type :: node()
  end)

  describe "the node type" do
    test "is itself" do
      assert type(node()) == @node_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :node, params: []} == @node_type
    end
  end
end
