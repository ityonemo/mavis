defmodule TypeTest.RemoteString.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "the elixir String.t" do
    test "is a subtype of itself and any" do
      assert type(String.t()) in type(String.t())
      assert type(String.t()) in any()
    end

    test "is a subtype of any bitstring with size 0" do
      assert type(String.t()) in bitstring()
      assert type(String.t()) in binary()
    end

    test "is a subtype of appropriate unions" do
      assert type(String.t()) in (bitstring() <|> atom())
      assert type(String.t()) in (binary() <|> atom())
      assert type(String.t()) in (type(String.t()) <|> atom())
    end

    test "is not a subtype of orthogonal types" do
      refute type(String.t()) in (atom() <|> integer())
    end
  end

  describe "basic binary" do
    test "is not a subtype of String.t()" do
      refute binary() in type(String.t())
    end
  end

  # make an exception for empty binary
  describe "empty binary" do
    test "is a subtype of String.t()" do
      assert %Bitstring{size: 0, unit: 0} in type(String.t())
    end
  end
end
