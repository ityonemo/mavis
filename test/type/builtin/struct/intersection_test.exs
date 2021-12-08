defmodule TypeTest.BuiltinStruct.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection
  @moduletag :struct

  import Type, only: :macros

  describe "the intersection of struct" do
    test "with any, map and struct is itself" do
      assert struct() == struct() <~> any()
      assert struct() == struct() <~> map()
      assert struct() == struct() <~> struct()
    end

    @literal %Type.Map{required: %{__struct__: FooBar, field: "value"}}
    test "with a valid struct literal" do
      assert @literal == struct() <~> @literal
    end

    test "with none is none" do
      assert none() == struct() <~> none()
    end

    test "with all other types is none" do
      []
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == struct() <~> target
      end)
    end
  end
end
