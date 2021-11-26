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
      assert "foo" > "bar"
    end

    test "is smaller than a bigger bitstring" do
      assert "foo" < "quux"
    end

    test "is smaller than binary, bitstring, and Strings, which it is a subset of" do
      assert "foo" < bitstring()
      assert "foo" < binary()
      assert "foo" < type(String.t())

      assert bitstring() > "foo"
      assert binary() > "foo"
      assert type(String.t()) > "foo"
    end

    test "is smaller than things outside of binaries" do
      assert "foo" < any()
    end
  end
end
