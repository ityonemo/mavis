defmodule TypeTest.BuiltinMap.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection
  @moduletag :map

  import Type, only: :macros

  describe "the intersection of map/0" do
    test "with any, map and map/0 is itself" do
      assert map() == map() <~> any()
      assert map() == map() <~> map()
    end

    test "with other specialized lists is them" do
      assert struct() == map() <~> struct()
    end

    @literal %Type.Map{required: %{"foo" => "bar"}}
    test "with a valid map literal" do
      assert @literal == map() <~> @literal
    end

    test "with none is none" do
      assert none() == map() <~> none()
    end

    test "with all other types is none" do
      [map()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == map() <~> target
      end)
    end
  end
end
