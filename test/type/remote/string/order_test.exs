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

    test "is bigger than actual binaries" do
      assert type(String.t()) > "foo"
      assert type(String.t()) > ""
    end
  end
end
