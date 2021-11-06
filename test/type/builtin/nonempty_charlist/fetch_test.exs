defmodule TypeTest.BuiltinNonemptyCharlist.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule NonemptyCharlist do
    @type nonempty_charlist_type :: nonempty_charlist()
  end)

  describe "the nonempty_charlist/0 type" do
    test "is itself" do
      assert nonempty_charlist() == @nonempty_charlist_type
    end

    test "is what we expect" do
      assert %Type.List{type: char(), final: []} == @nonempty_charlist_type
    end
  end
end
