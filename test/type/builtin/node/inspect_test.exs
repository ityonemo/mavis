defmodule TypeTest.BuiltinNode.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the node type" do
    pull_types(defmodule Node do
      @type node_type :: node
    end)

    test "looks like a node" do
      assert "type(node())" == inspect(@node_type)
    end

    test "code translates correctly" do
      assert @node_type == eval_inspect(@node_type)
    end
  end
end
