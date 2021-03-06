defmodule TypeTest.LiteralFloat.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  describe "a literal float" do
    test "is a subtype of itself" do
      assert 47.0 in 47.0
    end

    test "is a subtype of float and any builtins" do
      assert 47.0 in float()
      assert 47.0 in any()
    end

    test "is a subtype of unions with ranges and integer classes" do
      assert 47.0 in (47.0 <|> atom())
      assert 47.0 in (float() <|> atom())
    end

    test "is not a subtype of unions of orthogonal types" do
      refute 47.0 in (integer() <|> atom())
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([float()])
      |> Enum.each(fn target ->
        refute 47.0 in target
      end)
    end
  end

  describe "(supertest) float and any" do
    test "are not subtypes of a literal float" do
      refute float() in 47.0
      refute any() in 47.0
    end
  end
end
