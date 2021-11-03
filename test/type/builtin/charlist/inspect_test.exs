defmodule TypeTest.BuiltinCharlist.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the charlist type" do
    pull_types(defmodule Charlist do
      @type charlist_type :: charlist
    end)

    test "looks like a charlist" do
      assert "charlist()" == inspect(@charlist_type)
    end

    test "code translates correctly" do
      assert @charlist_type == eval_inspect(@charlist_type)
    end
  end
end
