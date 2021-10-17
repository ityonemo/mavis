defmodule TypeTest.LiteralBitstring.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "a literal bitstring" do
    test "is bigger than bottom" do
      assert "foo" > none()
    end

    test "is bigger than a smaller bitstring" do
      assert "foo" > literal("bar")
    end

    test "is smaller than a bigger bitstring" do
      assert "foo" < literal("quux")
    end

    test "is smaller than binary, bitstring, and Strings, which it is a subset of" do
      assert "foo" < bitstring()
      assert "foo" < binary()
      assert "foo" < remote(String.t())
      assert "foo" < remote(String.t(3))

      assert bitstring() > "foo"
      assert binary() > "foo"
      assert remote(String.t()) > "foo"
      assert remote(String.t(3)) > "foo"
    end

    test "is smaller than things outside of binaries" do
      assert "foo" < any()
    end
  end
end
