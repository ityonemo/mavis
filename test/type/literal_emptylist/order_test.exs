defmodule TypeTest.LiteralEmptyList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "an empty list literal" do
    test "is bigger than bottom and integers" do
      assert [] > builtin(:none)
      assert [] > builtin(:pid)
    end

    test "is bigger than any nonempty: true list" do
      assert [] > %Type.List{nonempty: true}
    end

    test "is smaller than a union containing it" do
      assert [] < [] <|> 0
    end

    test "is smaller than any nonempty: false list" do
      assert [] < %Type.List{nonempty: false}
    end

    test "is smaller than bitstring and top" do
      assert [] < builtin(%Type.Bitstring{size: 0, unit: 0})
      assert [] < builtin(:any)
    end
  end

end
