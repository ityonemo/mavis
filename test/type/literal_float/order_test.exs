defmodule TypeTest.LiteralFloat.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "a literal float" do
    test "is bigger than bottom" do
      assert 47.0 > none()
    end

    test "is bigger than a smaller integer" do
      assert 47.0 > 42.0
    end

    test "is smaller than a bigger integer" do
      assert 47.0 < 50.0
    end

    test "is smaller than float, which it is a subset of" do
      assert 47.0 < float()
    end

    test "is smaller than things outside of float" do
      assert 47.0 < atom()
      assert 47.0 < any()
    end
  end
end
