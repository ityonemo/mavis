defmodule TypeTest.BuiltinBitstring.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the bitstring/0 type" do
    @bitstring_type %Type.Bitstring{size: 0, unit: 1}

    test "matches with itself" do
      assert bitstring() = @bitstring_type
    end
  end
end
