defmodule TypeTest.BuiltinNonemptyList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the nonempty_list type" do
    pull_types(defmodule NonemptyList do
      @type nonempty_list_type :: nonempty_list()
    end)

    test "is presented as" do
      assert "type([...])" == inspect(@nonempty_list_type)
    end

    test "code translates correctly" do
      assert @nonempty_list_type == eval_type_str("type([...])")
    end
  end
end
