defmodule TypeTest.BuiltinAny.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the any/0 type" do
    @any_type %Type{module: nil, name: :any, params: []}

    test "matches with itself" do
      assert any() = @any_type
    end
  end
end
