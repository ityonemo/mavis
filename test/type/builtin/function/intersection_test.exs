defmodule TypeTest.BuiltinFunction.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of function" do
    test "with any and function is itself" do
      assert function() == function() <~> any()
      assert function() == function() <~> function()
    end

    test "with any function is the function" do
      assert type((atom() -> integer())) == function() <~> type((atom() -> integer()))
    end

    test "with none is none" do
      assert none() == function() <~> none()
    end

    test "with all other types is none" do
      type(( -> 0))
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == function() <~> target
      end)
    end
  end
end
