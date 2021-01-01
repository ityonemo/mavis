defmodule TypeTest.LiteralBinary.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "a literal bitstring" do
    test "is a subtype of itself" do
      assert "foo" in "foo"
    end

    test "is a subtype of bitstring, binary, Strings and any builtins" do
      assert "foo" in bitstring()
      assert "foo" in binary()
      assert "foo" in any()
    end

    test "is a subtype of Strings and specified binaries" do
      assert "foo" in remote(String.t())
      assert "foo" in remote(String.t(3))

      assert "foo" in %Bitstring{size: 24}
      assert "foo" in %Bitstring{unit: 8}
    end

    test "is a subtype of unions with ranges and integer classes" do
      assert "foo" in ("foo" <|> atom())
      assert "foo" in (binary() <|> atom())
    end

    test "is not a subtype of wrong bitstrings" do
      refute "foo" in %Bitstring{size: 21}
      refute "foo" in %Bitstring{unit: 7}
    end

    test "is not a subtype of unions of orthogonal types" do
      refute "foo" in (integer() <|> atom())
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([binary()])
      |> Enum.each(fn target ->
        refute "foo" in target
      end)
    end
  end

  describe "(supertest) list and any" do
    test "are not subtypes of a literal list" do
      refute binary() in "foo"
      refute any() in "foo"
    end
  end
end
