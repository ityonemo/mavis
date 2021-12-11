defmodule TypeTest.BuiltinFunction.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  
  @moduletag :inspect
  @moduletag :function

  describe "the function type" do
    pull_types(defmodule Function do
      @type function_type :: function
    end)

    test "looks like a function" do
      assert "function()" == inspect(@function_type)
    end

    test "code translates correctly" do
      assert @function_type == eval_inspect(@function_type)
    end
  end
end
