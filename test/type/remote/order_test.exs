defmodule TypeTest.Remote.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "elixir String.t" do
    test "is bigger than binary of unit 16" do
      assert remote(String.t()) > %Bitstring{size: 0, unit: 16}
      assert %Bitstring{size: 0, unit: 16} < remote(String.t())
    end

    test "is bigger than binary with any unit" do
      assert remote(String.t()) > %Bitstring{size: 8, unit: 8}
      assert %Bitstring{size: 8, unit: 8} < remote(String.t())
    end

    test "is smaller than binary" do
      assert remote(String.t()) < %Bitstring{size: 0, unit: 8}
      assert %Bitstring{size: 0, unit: 8} > remote(String.t())
    end
  end

  describe "String.t/1" do
    test "is smaller than general String.t and bigger than bigger String.t's" do
      assert remote(String.t(3)) < remote(String.t())
      assert remote(String.t(3)) > remote(String.t(4))
    end
  end
end
