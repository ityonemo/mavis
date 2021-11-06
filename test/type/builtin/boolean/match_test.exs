defmodule TypeTest.BuiltinBoolean.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the boolean/0 type" do
    @boolean_type %Type.Union{of: [true, false]}

    test "matches with itself" do
      assert boolean() = @boolean_type
    end
  end
end
