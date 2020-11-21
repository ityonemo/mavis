defmodule TypeTest.LiteralEmptyList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "an empty list literal" do
    test "is bigger than bottom and integers" do
      assert [] > none()
      assert [] > pid()
    end

    test "is bigger than any nonempty: true list" do
      assert [] > list(...)
    end

    test "is smaller than a union containing it" do
      assert [] < [] <|> 0
    end

    test "is smaller than any nonempty: false list" do
      assert [] < list()
    end

    test "is smaller than bitstring and top" do
      assert [] < %Type.Bitstring{size: 0, unit: 0}
      assert [] < any()
    end
  end
end
