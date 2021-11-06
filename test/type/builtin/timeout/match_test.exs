defmodule TypeTest.BuiltinTerm.TimeoutTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the timeout/0 type" do
    @timeout_type %Type.Union{of: [:infinity, pos_integer(), 0]}

    test "matches with itself" do
      assert timeout() = @timeout_type
    end
  end
end
