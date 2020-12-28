defmodule TypeTest.LiteralBitstring.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Bitstring

  @bitstring "foo"

  describe "the intersection of a literal bitstring" do
    test "with itself, bitstring and any is itself" do
      assert literal(@bitstring) == literal(@bitstring) <~> any()
      assert literal(@bitstring) == literal(@bitstring) <~> bitstring()
      assert literal(@bitstring) == literal(@bitstring) <~> binary()
      assert literal(@bitstring) == literal(@bitstring) <~> literal(@bitstring)

      assert literal(@bitstring) == any() <~> literal(@bitstring)
      assert literal(@bitstring) == bitstring() <~> literal(@bitstring)
      assert literal(@bitstring) == binary() <~> literal(@bitstring)
    end

    test "with correctly descriptive bitstring types" do
      assert literal(@bitstring) == literal(@bitstring) <~> %Bitstring{size: 24}
      assert literal(@bitstring) == literal(@bitstring) <~> %Bitstring{unit: 8}

      assert literal(@bitstring) == %Bitstring{size: 24} <~> literal(@bitstring)
      assert literal(@bitstring) == %Bitstring{unit: 8} <~> literal(@bitstring)
    end

    test "with other literal bitstrings" do
      assert none() == literal("baz") <~> literal(@bitstring)
    end

    test "with unions works as expected" do
      assert literal(@bitstring) == literal(@bitstring) <~> (:foo <|> literal(@bitstring))
      assert literal(@bitstring) == literal(@bitstring) <~> (:foo <|> bitstring())
      assert none() == literal(@bitstring) <~> (atom() <|> port())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([bitstring()])
      |> Enum.each(fn target ->
        assert none() == literal(@bitstring) <~> target
        assert none() == target <~> literal(@bitstring)
      end)
    end
  end
end
