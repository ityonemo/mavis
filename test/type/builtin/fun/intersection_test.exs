defmodule TypeTest.BuiltinFun.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection
  @moduletag :function

  import Type, only: :macros

  describe "the intersection of fun" do
    test "with any and fun is itself" do
      assert fun() == fun() <~> any()
      assert fun() == fun() <~> fun()
    end

    test "with any function is the function" do
      assert type((atom() -> integer())) == fun() <~> type((atom() -> integer()))
    end

    test "with none is none" do
      assert none() == fun() <~> none()
    end

    test "with all other types is none" do
      type(( -> 0))
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == fun() <~> target
      end)
    end
  end
end
