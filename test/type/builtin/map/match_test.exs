defmodule TypeTest.BuiltinMap.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch
  @moduletag :map

  describe "the map/0 type" do
    @map_type %Type.Map{optional: %{any() => any()}, required: %{}}

    test "matches with itself" do
      assert map() = @map_type
    end
  end
end
