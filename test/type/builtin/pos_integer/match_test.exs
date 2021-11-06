defmodule TypeTest.BuiltinPosInteger.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the pos_integer/0 type" do
    @pos_integer_type %Type{module: nil, name: :pos_integer, params: []}

    test "matches with itself" do
      assert pos_integer() = @pos_integer_type
    end
  end
end
