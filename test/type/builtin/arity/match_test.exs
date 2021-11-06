defmodule TypeTest.BuiltinArity.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the arity/0 type" do
    @arity_type 0..255

    test "matches with itself" do
      assert arity() = @arity_type
    end
  end
end
