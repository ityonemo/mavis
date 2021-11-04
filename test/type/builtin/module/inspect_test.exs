defmodule TypeTest.BuiltinModule.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the module type" do
    pull_types(defmodule Module do
      @type module_type :: module
    end)

    test "looks like a module" do
      assert "module()" == inspect(@module_type)
    end

    test "code translates correctly" do
      assert @module_type == eval_inspect(@module_type)
    end
  end
end
