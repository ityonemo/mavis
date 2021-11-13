defmodule TypeTest.BuiltinAny.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of any" do
    test "with all other types is itself" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert target == any() <~> target
      end)
    end
  end
end
