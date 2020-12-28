defmodule TypeTest.LiteralBitstring.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  @bitstring "foo"

  describe "a literal list" do
    test "is bigger than bottom" do
      assert literal(@bitstring) > none()
    end

    test "is bigger than a smaller bitstring" do
      assert literal(@bitstring) > literal("bar")
    end

    test "is smaller than a bigger bitstring" do
      assert literal(@bitstring) < literal("quux")
    end

    test "is smaller than binary, bitstring, and Strings, which it is a subset of" do
      assert literal(@bitstring) < bitstring()
      assert literal(@bitstring) < binary()
      assert literal(@bitstring) < remote(String.t())
      assert literal(@bitstring) < remote(String.t(3))
    end

    test "is smaller than things outside of binaries" do
      assert literal(@bitstring) < any()
    end
  end
end
