defmodule TypeTest.LiteralFloat.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  describe "a literal float" do
    test "is a subtype of itself" do
      assert literal(47.0) in literal(47.0)
    end

    test "is a subtype of float and any builtins" do
      assert literal(47.0) in float()
      assert literal(47.0) in any()
    end

    test "is a subtype of unions with ranges and integer classes" do
      assert literal(47.0) in (literal(47.0) <|> atom())
      assert literal(47.0) in (float() <|> atom())
    end

    test "is not a subtype of unions of orthogonal types" do
      refute literal(47.0) in (integer() <|> atom())
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([float()])
      |> Enum.each(fn target ->
        refute literal(47.0) in target
      end)
    end
  end

  describe "(supertest) float and any" do
    test "are not subtypes of a literal float" do
      refute float() in literal(47.0)
      refute any() in literal(47.0)
    end
  end
end
