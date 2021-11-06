defmodule TypeTest.BuiltinNonNegInteger.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the non_neg_integer/0 type" do
    @non_neg_integer_type %Type.Union{of: [pos_integer(), 0]}

    test "matches with itself" do
      assert non_neg_integer() = @non_neg_integer_type
    end
  end
end
