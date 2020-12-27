defmodule TypeTest.LiteralList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  @list [:foo, :bar]

  describe "the intersection of a literal list" do
    test "with itself, list and any is itself" do
      assert literal(@list) == literal(@list) <~> any()
      assert literal(@list) == literal(@list) <~> list()
      assert literal(@list) == literal(@list) <~> literal(@list)

      assert literal(@list) == any() <~> literal(@list)
      assert literal(@list) == list() <~> literal(@list)
    end

    test "with correctly descriptive list types" do
      assert literal(@list) == literal(@list) <~> list(:foo <|> :bar)
      assert literal(@list) == literal(@list) <~> list(atom())

      assert literal(@list) == list(:foo <|> :bar) <~> literal(@list)
      assert literal(@list) == list(atom()) <~> literal(@list)
    end

    test "with other literal lists" do
      assert none() == literal([:foo, "bar"]) <~> literal(@list)
      assert none() == literal([:foo]) <~> literal(@list)
      assert none() == literal([:foo, :bar, :baz]) <~> literal(@list)
    end

    test "with unions works as expected" do
      assert literal(@list) == literal(@list) <~> (:foo <|> literal(@list))
      assert literal(@list) == literal(@list) <~> (:foo <|> list())
      assert none() == literal(@list) <~> (atom() <|> port())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([list()])
      |> Enum.each(fn target ->
        assert none() == literal(@list) <~> target
        assert none() == target <~> literal(@list)
      end)
    end
  end
end
