defmodule TypeTest.BuiltinIdentifier.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the identifier/0 type" do
    @identifier_type %Type.Union{
      of: [pid(), port(), reference()]}

    test "matches with itself" do
      assert identifier() = @identifier_type
    end
  end
end
