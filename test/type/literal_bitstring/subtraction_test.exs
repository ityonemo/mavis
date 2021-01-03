defmodule TypeTest.LiteralBitstring.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Bitstring

  describe "the subtraction from a literal bitstring" do
    test "of itself, bitstring and any is itself" do
      assert none() == "foo" - any()
      assert none() == "foo" - bitstring()
      assert none() == "foo" - binary()
      assert none() == "foo" - "foo"
    end

    test "of correctly descriptive bitstring types" do
      assert none() == "foo" - %Bitstring{size: 24}
      assert none() == "foo" - %Bitstring{unit: 8}

      assert none() == "foo" - remote(String.t())
      assert none() == "foo" - remote(String.t(3))
    end

    test "of other literal bitstrings" do
      assert "foo" == "foo" - "bar"
    end

    test "of mismatched bitstring types" do
      assert "foo" == "foo" - %Bitstring{size: 21}
      assert "foo" == "foo" - %Bitstring{unit: 7}

      assert <<255>> == <<255>> - remote(String.t())
      assert <<255>> == <<255>> - remote(String.t(1))
      assert "foo" == "foo" - remote(String.t(4))
    end

    test "of unions works as expected" do
      assert none() == "foo" - (:foo <|> "foo")
      assert none() == "foo" - (:foo <|> bitstring())
      assert "foo" == "foo" - (atom() <|> port())
    end

    test "of all other types is none" do
      TypeTest.Targets.except(["foo", bitstring()])
      |> Enum.each(fn target ->
        assert "foo" == "foo" - target
      end)
    end
  end
end
