defmodule TypeTest.BuiltinByte.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the byte/0 type" do
    @byte_type 0..255

    test "matches with itself" do
      assert byte() = @byte_type
    end
  end
end
