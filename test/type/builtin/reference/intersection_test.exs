defmodule TypeTest.BuiltinReference.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of reference" do
    test "with any and reference is itself" do
      assert reference() == reference() <~> any()
      assert reference() == reference() <~> reference()
    end

    test "with none is none" do
      assert none() == reference() <~> none()
    end

    test "with all other types is none" do
      [reference()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == reference() <~> target
      end)
    end
  end
end
