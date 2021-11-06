defmodule TypeTest.BuiltinCharlist.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the charlist/0 type" do
    @charlist_type %Type.Union{of: [%Type.List{type: char(), final: []}, []]}

    test "matches with itself" do
      assert charlist() = @charlist_type
    end
  end
end
