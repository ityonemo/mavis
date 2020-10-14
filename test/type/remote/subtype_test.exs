defmodule TypeTest.Remote.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  @basic_bitstring %Bitstring{size: 0, unit: 1}
  @basic_binary    %Bitstring{size: 0, unit: 8}

  describe "the elixir String.t" do
    test "is a subtype of itself and any" do
      assert remote(String.t()) in remote(String.t())
      assert remote(String.t()) in builtin(:any)
    end

    test "is a subtype of any bitstring with size 0" do
      assert remote(String.t()) in @basic_bitstring
      assert remote(String.t()) in @basic_binary
    end

    test "is a subtype of appropriate unions" do
      assert remote(String.t()) in (@basic_bitstring <|> builtin(:atom))
      assert remote(String.t()) in (@basic_binary <|> builtin(:atom))
      assert remote(String.t()) in (remote(String.t()) <|> builtin(:atom))
    end

    test "is not a subtype of orthogonal types" do
      refute remote(String.t()) in (builtin(:atom) <|> builtin(:integer))
    end
  end

  describe "basic binary" do
    test "is not a subtype of String.t()" do
      refute @basic_binary in remote(String.t())
    end
  end

  # make an exception for empty binary
  describe "empty binary" do
    test "is a subtype of String.t()" do
      assert %Bitstring{size: 0, unit: 0} in String.t()
    end
  end
end
