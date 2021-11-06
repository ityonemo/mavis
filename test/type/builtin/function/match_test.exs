defmodule TypeTest.Builtin.Function.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the function/0 type" do
    @function_type %Type.Function{params: :any, return: any()}

    test "matches with itself" do
      assert function() = @function_type
    end
  end
end
