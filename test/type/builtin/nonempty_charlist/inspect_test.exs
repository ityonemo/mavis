defmodule TypeTest.BuiltinNonemptyCharlist.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the nonempty_charlist type" do
    pull_types(defmodule NonemptyCharlist do
      @type nonempty_charlist_type :: nonempty_charlist
    end)

    test "looks like itself" do
      assert "nonempty_charlist()" == inspect(@nonempty_charlist_type)
    end

    test "code translates correctly" do
      assert @nonempty_charlist_type == eval_inspect(@nonempty_charlist_type)
    end
  end
end
