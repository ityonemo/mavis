defmodule TypeTest.BuiltinNone.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of none" do
    test "with any and itself is none" do
      assert none() == none() <~> any()
      assert none() == none() <~> none()
    end

    test "with all other types is none" do
      []
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == none() <~> target
      end)
    end
  end
end
