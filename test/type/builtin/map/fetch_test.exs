defmodule TypeTest.BuiltinMap.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the map type" do
    pull_types(defmodule Map do
      @type map_type :: map
    end)

    test "is itself" do
      assert map() == @map_type
    end

    test "matches to itself" do
      assert map() = @map_type
    end

    test "is what we expect" do
      assert %Type.Map{
        optional: %{any => any},
        required: %{}
      } == @map_type 
    end
  end
end
