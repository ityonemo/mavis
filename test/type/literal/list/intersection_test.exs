defmodule TypeTest.LiteralList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.List

  @list [:foo, :bar]
  @ilist ["foo" | "bar"]

  describe "the intersection of a literal list" do
    test "with itself, list and any is itself" do
      assert @list == @list <~> any()
      assert @list == @list <~> list()
      assert @list == @list <~> @list

      assert @list == any() <~> @list
      assert @list == list() <~> @list

      assert @ilist == @ilist <~> any()
      assert @ilist == any() <~> @ilist
      assert @ilist == @ilist <~> @ilist
    end

    test "iolist literals intersect with iolist" do
      assert @ilist == @ilist <~> iolist()
    end

    test "with correctly descriptive list types" do
      assert @list == @list <~> list(:foo <|> :bar)
      assert @list == @list <~> list(atom())

      assert @ilist == @ilist <~> %List{final: type(String.t)}
      assert @ilist == @ilist <~> maybe_improper_list()
      assert @ilist == @ilist <~> nonempty_maybe_improper_list()
    end

    test "with wrong finals" do
      assert none() == @ilist <~> list()

      assert none() == @list <~> %List{final: type(String.t)}
    end

    test "with other literal lists" do
      assert none() == @ilist <~> [:foo, "bar"]
      assert none() == @ilist <~> [:foo]
      assert none() == @ilist <~> [:foo, :bar, :baz]

      assert none() == @ilist <~> ["foo" | "baz"]
    end

    test "with unions works as expected" do
      assert @list == @list <~> (:foo <|> @list)
      assert @list == @list <~> (:foo <|> list())
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
