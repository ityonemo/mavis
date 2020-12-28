defmodule TypeTest.LiteralBinary.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  @bitstring "foo"

  alias Type.Bitstring

  describe "a literal bitstring" do
    test "is a subtype of itself" do
      assert literal(@bitstring) in literal(@bitstring)
    end

    test "is a subtype of bitstring, binary, Strings and any builtins" do
      assert literal(@bitstring) in bitstring()
      assert literal(@bitstring) in binary()
      assert literal(@bitstring) in any()
    end

    test "is a subtype of Strings and specified binaries" do
      assert literal(@bitstring) in remote(String.t())
      assert literal(@bitstring) in remote(String.t(3))

      assert literal(@bitstring) in %Bitstring{size: 24}
      assert literal(@bitstring) in %Bitstring{unit: 8}
    end

    test "is a subtype of unions with ranges and integer classes" do
      assert literal(@bitstring) in (literal(@bitstring) <|> atom())
      assert literal(@bitstring) in (binary() <|> atom())
    end

    test "is not a subtype of wrong bitstrings" do
      refute literal(@bitstring) in %Bitstring{size: 21}
      refute literal(@bitstring) in %Bitstring{unit: 7}
    end

    test "is not a subtype of unions of orthogonal types" do
      refute literal(@bitstring) in (integer() <|> atom())
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([binary()])
      |> Enum.each(fn target ->
        refute literal(@bitstring) in target
      end)
    end
  end

  describe "(supertest) list and any" do
    test "are not subtypes of a literal list" do
      refute binary() in literal(@bitstring)
      refute any() in literal(@bitstring)
    end
  end
end
