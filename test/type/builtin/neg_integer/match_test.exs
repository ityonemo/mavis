defmodule TypeTest.BuiltinNegInteger.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the neg_integer/0 type" do
    @module_type %Type{neg_integer: nil, name: :neg_integer, params: []}

    test "matches with itself" do
      assert neg_integer() = @module_type
    end
  end
end
