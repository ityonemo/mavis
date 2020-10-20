defmodule TypeTest.TypeBitstring.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Bitstring

  describe "a bitstring" do
    test "is bigger than bottom and reference" do
      assert %Bitstring{size: 0, unit: 0} > builtin(:none)
      assert %Bitstring{size: 0, unit: 0} > builtin(:reference)
    end

    test "is bigger than a fixed size bitstring" do
      assert %Bitstring{size: 0, unit: 1} > %Bitstring{size: 16, unit: 0}
      assert %Bitstring{size: 16, unit: 0} < %Bitstring{size: 0, unit: 1}
    end

    test "is bigger than a bitstring with a bigger unit or size" do
      assert %Bitstring{size: 0, unit: 1} > %Bitstring{size: 0, unit: 8}
      assert %Bitstring{size: 0, unit: 8} > %Bitstring{size: 8, unit: 8}
    end

    test "is bigger than a union with a smaller bitstring" do
      assert %Bitstring{size: 0, unit: 1} > %Bitstring{size: 0, unit: 8} <|> :foo
    end

    test "is smaller than a bitstring with a smaller unit or size" do
      assert %Bitstring{size: 0, unit: 8} < %Bitstring{size: 0, unit: 1}
      assert %Bitstring{size: 8, unit: 8} < %Bitstring{size: 0, unit: 8}
    end

    test "is smaller than a union with the same bitstring" do
      assert %Bitstring{size: 0, unit: 8} < %Bitstring{size: 0, unit: 8} <|> :foo
      assert %Bitstring{size: 0, unit: 8} < %Bitstring{size: 0, unit: 8} <|> :foo
    end

    test "is smaller than top" do
      assert %Bitstring{size: 0, unit: 0} < builtin(:any)
    end
  end
end
