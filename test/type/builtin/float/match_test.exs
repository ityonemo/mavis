defmodule TypeTest.BuiltinFloat.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the float/0 type" do
    @float_type %Type{module: nil, name: :float, params: []}

    test "matches with itself" do
      assert float() = @float_type
    end
  end
end
