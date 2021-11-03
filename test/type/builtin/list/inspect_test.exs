defmodule TypeTest.BuiltinList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the list type" do
    pull_types(defmodule List do
      @type list_type :: list
      @type list_param_type :: list(atom())
    end)

    test "looks like a list" do
      assert "list()" == inspect(@list_type)
    end

    test "code translates correctly" do
      assert @list_type == eval_inspect(@list_type)
    end

    test "looks like a list with a parameter" do
      assert "type([atom()])" == inspect(@list_param_type)
    end

    test "with a parameter code translates correctly" do
      assert @list_param_type == eval_type_str("list(atom())")
    end
  end
end
