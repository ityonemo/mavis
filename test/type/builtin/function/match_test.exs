defmodule TypeTest.Builtin.Function.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch
  @moduletag :function

  describe "the function/0 type" do
    @function_type %Type.Function{branches: [%Type.Function.Branch{params: :any, return: any()}]}

    test "matches with itself" do
      assert function() = @function_type
    end
  end
end
