defmodule TypeTest.LiteralBitstring.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Bitstring

  describe "the intersection of a literal bitstring" do
    test "with itself, bitstring and any is itself" do
      assert "foo" == "foo" <~> any()
      assert "foo" == "foo" <~> bitstring()
      assert "foo" == "foo" <~> binary()
      assert "foo" == "foo" <~> "foo"

      assert "foo" == any() <~> "foo"
      assert "foo" == bitstring() <~> "foo"
      assert "foo" == binary() <~> "foo"
    end

    test "with correctly descriptive bitstring types" do
      assert "foo" == "foo" <~> %Bitstring{size: 24}
      assert "foo" == "foo" <~> %Bitstring{unit: 8}

      assert "foo" == %Bitstring{size: 24} <~> "foo"
      assert "foo" == %Bitstring{unit: 8} <~> "foo"

      assert "foo" == "foo" <~> remote(String.t())
      assert "foo" == "foo" <~> remote(String.t(3))
      assert "foo" == remote(String.t()) <~> "foo"
      assert "foo" == remote(String.t(3)) <~> "foo"
    end

    test "with other literal bitstrings" do
      assert none() == literal("baz") <~> "foo"
    end

    test "with mismatched bitstring types" do
      assert none() == "foo" <~> %Bitstring{size: 21}
      assert none() == "foo" <~> %Bitstring{unit: 7}
      assert none() == "foo" <~> remote(String.t(4))
    end

    test "with unions works as expected" do
      assert "foo" == "foo" <~> (:foo <|> "foo")
      assert "foo" == "foo" <~> (:foo <|> bitstring())
      assert none() == "foo" <~> (atom() <|> port())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([bitstring()])
      |> Enum.each(fn target ->
        assert none() == "foo" <~> target
        assert none() == target <~> "foo"
      end)
    end
  end
end
