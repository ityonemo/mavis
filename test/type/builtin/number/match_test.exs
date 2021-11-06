defmodule TypeTest.BuiltinNumber.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the number/0 type" do
    @number_type %Type.Union{of: [float(), pos_integer(), 0, neg_integer()]}

    test "matches with itself" do
      assert number() = @number_type
    end
  end
end
