defmodule TypeTest.Remote.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "the elixir String.t" do
    test "is a subtype of itself and any" do
      assert remote(String.t()) in remote(String.t())
      assert remote(String.t()) in any()
    end

    test "is a subtype of any bitstring with size 0" do
      assert remote(String.t()) in bitstring()
      assert remote(String.t()) in binary()
    end

    test "is a subtype of appropriate unions" do
      assert remote(String.t()) in (bitstring() <|> atom())
      assert remote(String.t()) in (binary() <|> atom())
      assert remote(String.t()) in (remote(String.t()) <|> atom())
    end

    test "is not a subtype of orthogonal types" do
      refute remote(String.t()) in (atom() <|> integer())
    end
  end

  describe "the elixir String.t/1" do
    test "is a subtype of itself, general String.t" do
      assert remote(String.t(3)) in remote(String.t(3))
      assert remote(String.t(3)) in remote(String.t())
      assert remote(String.t(3)) in any()
    end

    test "is a subtype of any with the correct size" do
      assert remote(String.t(3)) in %Bitstring{unit: 8}
      assert remote(String.t(3)) in %Bitstring{unit: 24}
      assert remote(String.t(3)) in %Bitstring{size: 24}
      assert remote(String.t(3)) in %Bitstring{size: 8, unit: 8}
    end
  end

  describe "basic binary" do
    test "is not a subtype of String.t()" do
      refute binary() in remote(String.t())
    end
  end

  # make an exception for empty binary
  describe "empty binary" do
    test "is a subtype of String.t()" do
      assert %Bitstring{size: 0, unit: 0} in remote(String.t())
    end
  end
end
