defmodule TypeTest.BuiltinNonEmptyCharlist.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the nonempty_charlist/0 type" do
    @nonempty_charlist_type %Type.List{type: char(), final: []}

    test "matches with itself" do
      assert nonempty_charlist() = @nonempty_charlist_type
    end
  end
end
