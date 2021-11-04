defmodule TypeTest.BuiltinFloat.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the float type" do
    pull_types(defmodule Float do
      @type float_type :: float
    end)

    test "looks like a float" do
      assert "float()" == inspect(@float_type)
    end

    test "code translates correctly" do
      assert @float_type == eval_inspect(@float_type)
    end
  end
end
