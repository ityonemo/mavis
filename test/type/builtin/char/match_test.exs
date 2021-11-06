defmodule TypeTest.BuiltinChar.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the char/0 type" do
    @char_type 0..0x10_FFFF

    test "matches with itself" do
      assert char() = @char_type
    end
  end
end
