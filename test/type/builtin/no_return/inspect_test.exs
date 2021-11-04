defmodule TypeTest.BuiltinNoReturn.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the no_return type" do
    pull_types(defmodule NoReturn do
      @type no_return_type :: no_return
    end)

    test "looks like a none" do
      assert "none()" == inspect(@no_return_type)
    end

    test "code translates correctly" do
      assert @no_return_type == eval_type_str("no_return()")
    end
  end
end
