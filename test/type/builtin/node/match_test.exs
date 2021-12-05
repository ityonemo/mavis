defmodule TypeTest.BuiltinNode.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the node/0 type" do
    @node_type %Type{module: nil, name: :node, params: []}

    test "matches with itself" do
      assert type(node()) = @node_type
    end
  end
end
