defmodule TypeTest.LiteralFloat.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  @list [:foo, :bar]

  describe "a literal list" do
    test "is a subtype of itself" do
      assert @list in @list
    end

    test "is a subtype of list and any builtins" do
      assert @list in list()
      assert @list in any()
    end

    test "is a subtype of lists with specified types" do
      assert @list in list(:foo <|> :bar)
      assert @list in list(atom())
      assert @list in list(:foo <|> :bar <|> :baz)
    end

    test "is a subtype of unions with ranges and integer classes" do
      assert @list in (@list <|> atom())
      assert @list in (list() <|> atom())
    end

    test "is not a subtype of underdetermined lists" do
      refute @list in list(:foo)
    end

    test "is not a subtype of unions of orthogonal types" do
      refute @list in (integer() <|> atom())
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([list()])
      |> Enum.each(fn target ->
        refute @list in target
      end)
    end
  end

  describe "(supertest) list and any" do
    test "are not subtypes of a literal list" do
      refute list() in @list
      refute any() in @list
    end
  end
end
