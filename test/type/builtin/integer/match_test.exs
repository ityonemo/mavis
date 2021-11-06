defmodule TypeTest.BuiltinInteger.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the integer/0 type" do
    @integer_type %Type.Union{
      of: [pos_integer(), 0, neg_integer()]}

    test "matches with itself" do
      assert integer() = @integer_type
    end
  end
end
