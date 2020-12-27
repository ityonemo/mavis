defmodule TypeTest.LiteralFloat.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "a literal float" do
    test "is bigger than bottom" do
      assert literal(47.0) > none()
    end

    test "is bigger than a smaller integer" do
      assert literal(47.0) > literal(42.0)
    end

    test "is smaller than a bigger integer" do
      assert literal(47.0) < literal(50.0)
    end

    test "is smaller than float, which it is a subset of" do
      assert literal(47.0) < float()
    end

    test "is smaller than things outside of float" do
      assert literal(47.0) < atom()
      assert literal(47.0) < any()
    end
  end
end
