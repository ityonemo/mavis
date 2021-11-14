defmodule TypeTest.BuiltinNoReturn.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of no_return" do
    test "with any and itself is none" do
      assert none() == no_return() <~> any()
      assert none() == no_return() <~> no_return()
    end

    test "with all other types is none" do
      []
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == no_return() <~> target
      end)
    end
  end
end
