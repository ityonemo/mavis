defmodule TypeTest.BuiltinList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the list type" do
    pull_types(defmodule List do
      @type list_type :: list
    end)

    test "looks like a list" do
      assert "list()" == inspect(@list_type)
    end

    test "code translates correctly" do
      assert @list_type == eval_inspect(@list_type)
    end
  end
end
