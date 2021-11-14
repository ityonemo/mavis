defmodule TypeTest.Builtin.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of tuple" do
    test "with any, and tuple is itself" do
      assert tuple() == tuple() <~> any()
      assert tuple() == tuple() <~> tuple()
    end

    @fixed_tuple %Type.Tuple{elements: [:foo], fixed: true}
    @free_tuple %Type.Tuple{elements: [:foo], fixed: false}
    test "with any tuple is the tuple" do
      assert @fixed_tuple == tuple() <~> @fixed_tuple
      assert @free_tuple == tuple() <~> @free_tuple
    end

    test "with none is none" do
      assert none() == tuple() <~> none()
    end

    test "with all other types is none" do
      []
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == tuple() <~> target
      end)
    end
  end
end
