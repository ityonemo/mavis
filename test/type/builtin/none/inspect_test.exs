defmodule TypeTest.BuiltinNone.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the none type" do
    pull_types(defmodule None do
      @type none_type :: none
    end)

    test "looks like a none" do
      assert "none()" == inspect(@none_type)
    end

    test "code translates correctly" do
      assert @none_type == eval_inspect(@none_type)
    end
  end
end
