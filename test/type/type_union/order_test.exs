defmodule TypeTest.TypeUnion.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Union

  describe "a union" do
    test "is bigger than bottom and pid" do
      assert %Union{of: [1, :foo]} > builtin(:none)
      assert %Union{of: [1, :foo]} < builtin(:any)
    end

    test "is just bigger than its biggest element" do
      assert %Union{of: [1, 3]} > 3
      assert %Union{of: [1, 3]} < 4
      assert %Union{of: [1, 3..4]} > 3..4
      assert %Union{of: [1..2, 4]} < 3..5
      assert %Union{of: [1, 3..4]} < 3..5
    end

    test "for integer ranges if everything is in the range it's smaller" do
      assert %Union{of: [1, 3..4]} < 0..4
      assert %Union{of: [1..2, 4]} < 0..4
    end

    test "is bigger when it's categorically bigger" do
      assert %Union{of: [1, builtin(:atom)]} > builtin(:atom)
      assert %Union{of: [1, :atom]} > :atom
    end
  end
end
