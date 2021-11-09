defmodule TypeTest.TypeBitstring.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "a bitstring" do
    test "is bigger than bottom and reference" do
      assert %Bitstring{size: 0, unit: 0} > none()
      assert %Bitstring{size: 0, unit: 0} > reference()
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
      assert %Bitstring{size: 0, unit: 0} < any()
    end
  end

  describe "the zero bitstring type" do
    test "is bigger than the empty bitstring" do
      assert %Bitstring{size: 0, unit: 0} > ""
    end
  end

  describe "binary" do
    test "is bigger than String.t" do
      assert binary() > type(String.t())
    end

    test "is bigger than binary literals" do
      assert binary() > "foo"
      assert binary() > ""
    end
  end
end
