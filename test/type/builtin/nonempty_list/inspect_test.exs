defmodule TypeTest.BuiltinNonemptyList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the nonempty_list type" do
    pull_types(defmodule NonemptyList do
      @type nonempty_list_type :: nonempty_list()
      @type nonempty_list_param_type :: nonempty_list(atom())
    end)

    test "is presented as" do
      assert "type([...])" == inspect(@nonempty_list_type)
    end

    test "code translates correctly" do
      assert @nonempty_list_type == eval_type_str("type([...])")
    end

    test "with parameter is presented as" do
      assert "type([atom(), ...])" == inspect(@nonempty_list_param_type)
    end

    test "with parameter code translates correctly" do
      assert @nonempty_list_param_type == eval_type_str("nonempty_list(atom())")
    end
  end
end
