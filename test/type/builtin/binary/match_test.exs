defmodule TypeTest.BuiltinBinary.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the binary/0 type" do
    @binary_type %Type.Bitstring{size: 0, unit: 8}

    test "matches with itself" do
      assert binary() = @binary_type
    end
  end
end
