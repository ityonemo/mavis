defmodule TypeTest.BuiltinTerm.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of term" do
    test "with none is none" do
      assert none() == term() <~> none()
    end

    test "with all other types is itself" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert target == term() <~> target
      end)
    end
  end
end
