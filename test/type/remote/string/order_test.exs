defmodule TypeTest.RemoteString.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "elixir String.t" do
    test "is bigger than binary of unit 16" do
      assert type(String.t()) > %Bitstring{size: 0, unit: 16}
    end

    test "is bigger than binary with any unit" do
      assert type(String.t()) > %Bitstring{size: 8, unit: 8}
    end

    test "is smaller than binary" do
      assert type(String.t()) < binary()
    end

    test "is bigger than a String.t with a size" do
      assert type(String.t()) > type(String.t(10))
    end

    test "is bigger than actual binaries" do
      assert type(String.t()) > "foo"
      assert type(String.t()) > ""
    end
  end

  describe "String.t/1" do
    test "is smaller than general String.t and bigger than bigger String.t's" do
      assert type(String.t(3)) < type(String.t())
      assert type(String.t(3)) > type(String.t(4))
    end

    test "is smaller than its corresponding raw bitstring type" do
      assert type(String.t(3)) < %Bitstring{size: 0, unit: 24}
    end

    test "is bigger than its corresponding raw bitstring type with a size" do
      assert type(String.t(3)) > %Bitstring{size: 8, unit: 24}
    end

    test "is bigger than actual binaries" do
      assert type(String.t(3)) > "foo"
    end
  end
end
