defmodule TypeTest.BuiltinNoReturn.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the no_return/0 type" do
    @no_return_type %Type{module: nil, name: :none, params: []}

    test "matches with itself" do
      assert no_return() = @no_return_type
    end
  end
end
