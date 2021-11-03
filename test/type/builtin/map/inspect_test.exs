defmodule TypeTest.BuiltinMap.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the map type" do
    pull_types(defmodule Map do
      @type map_type :: map
    end)

    test "looks like a map" do
      assert "map()" == inspect(@map_type)
    end

    test "code translates correctly" do
      assert @map_type == eval_inspect(@map_type)
    end
  end
end
