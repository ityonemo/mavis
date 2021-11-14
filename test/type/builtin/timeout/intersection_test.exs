defmodule TypeTest.BuiltinTimeout.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of timeout" do
    test "with any and timeout is itself" do
      assert timeout() == timeout() <~> any()
      assert timeout() == timeout() <~> timeout()
    end

    test "with any timeout subtype is the subtype" do
      assert pos_integer() == timeout() <~> pos_integer()
      assert non_neg_integer() == timeout() <~> non_neg_integer()
      assert :infinity == timeout() <~> :infinity
    end

    test "with overlapping types" do
      assert non_neg_integer() == timeout() <~> integer()
      assert :infinity == timeout() <~> atom()
    end

    test "with none is none" do
      assert none() == timeout() <~> none()
    end

    test "with all other types is none" do
      [0, 47, -10..10, pos_integer(), atom()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == timeout() <~> target
      end)
    end
  end
end
