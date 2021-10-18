defmodule TypeTest.LiteralBitstring.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Bitstring

  describe "the intersection of a literal bitstring" do
    @tag :skip
    test "with itself, bitstring and any is itself" do
      assert "foo" == "foo" <~> any()
      assert "foo" == "foo" <~> bitstring()
      assert "foo" == "foo" <~> binary()
      assert "foo" == "foo" <~> "foo"
    end

    @tag :skip
    test "with correctly descriptive bitstring types" do
      assert "foo" == "foo" <~> %Bitstring{size: 24}
      assert "foo" == "foo" <~> %Bitstring{unit: 8}

      assert "foo" == "foo" <~> remote(String.t())
      assert "foo" == "foo" <~> remote(String.t(3))
    end

    @tag :skip
    test "with other literal bitstrings" do
      assert none() == "baz" <~> "foo"
    end

    @tag :skip
    test "with mismatched bitstring types" do
      assert none() == "foo" <~> %Bitstring{size: 21}
      assert none() == "foo" <~> %Bitstring{unit: 7}
      assert none() == "foo" <~> remote(String.t(4))
    end

    @tag :skip
    test "with unions works as expected" do
      assert "foo" == "foo" <~> (:foo <|> "foo")
      assert "foo" == "foo" <~> (:foo <|> bitstring())
      assert none() == "foo" <~> (atom() <|> port())
    end

    @tag :skip
    test "with all other types is none" do
      TypeTest.Targets.except([bitstring(), "foo"])
      |> Enum.each(fn target ->
        assert none() == "foo" <~> target
      end)
    end
  end
end
