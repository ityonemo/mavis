defmodule TypeTest.LiteralList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  @list [:foo, :bar]

  describe "the intersection of a literal list" do
    test "with itself, list and any is itself" do
      assert @list == @list <~> any()
      assert @list == @list <~> list()
      assert @list == @list <~> @list

      assert @list == any() <~> @list
      assert @list == list() <~> @list
    end

    test "with correctly descriptive list types" do
      assert @list == @list <~> list(:foo <|> :bar)
      assert @list == @list <~> list(atom())

      assert @list == list(:foo <|> :bar) <~> @list
      assert @list == list(atom()) <~> @list
    end

    test "with other literal lists" do
      assert none() == literal([:foo, "bar"]) <~> @list
      assert none() == literal([:foo]) <~> @list
      assert none() == literal([:foo, :bar, :baz]) <~> @list
    end

    test "with unions works as expected" do
      assert @list == @list <~> (:foo <|> @list)
      assert @list == @list <~> (:foo <|> list())
      assert none() == @list <~> (atom() <|> port())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([list()])
      |> Enum.each(fn target ->
        assert none() == @list <~> target
        assert none() == target <~> @list
      end)
    end
  end
end
