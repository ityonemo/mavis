defmodule TypeTest.Builtin.Fun.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the fun/0 type" do
    @fun_type %Type.Function{params: :any, return: any()}

    test "matches with itself" do
      assert fun() = @fun_type
    end
  end
end
