defmodule TypeTest.BuiltinAny.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.FetchCase
  import TypeTest.InspectCase

  @moduletag :inspect

  describe "the any type" do
    pull_types(defmodule Any do
      @type any_type :: any
    end)

    test "looks like an any" do
      assert "any()" == inspect(@any_type)
    end

    test "code translates correctly" do
      assert @any_type == eval_inspect(@any_type)
    end
  end
end
