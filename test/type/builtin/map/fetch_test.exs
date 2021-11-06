defmodule TypeTest.BuiltinMap.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Map do
    @type map_type :: map
  end)

  describe "the map/0 type" do
    test "is itself" do
      assert map() == @map_type
    end

    test "is what we expect" do
      assert %Type.Map{
        optional: %{any => any},
        required: %{}
      } == @map_type
    end
  end
end
