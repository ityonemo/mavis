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
      assert @ilist == iolist() <~> @ilist
      assert @ilist == @ilist <~> iolist()
    end

    test "with correctly descriptive list types" do
      assert @list == @list <~> list(:foo <|> :bar)
      assert @list == @list <~> list(atom())

      assert @list == list(:foo <|> :bar) <~> @list
      assert @list == list(atom()) <~> @list

      assert @ilist == @ilist <~> %List{final: remote(String.t)}
      assert @ilist == @ilist <~> maybe_improper_list()
      assert @ilist == @ilist <~> nonempty_maybe_improper_list()

      assert @ilist == %List{final: remote(String.t)} <~> @ilist
      assert @ilist == maybe_improper_list() <~> @ilist
      assert @ilist == nonempty_maybe_improper_list() <~> @ilist
    end

    test "with wrong finals" do
      assert none() == @ilist <~> list()
      assert none() == list() <~> @ilist

      assert none() == @list <~> %List{final: remote(String.t)}
      assert none() == %List{final: remote(String.t)} <~> @list
    end

    #@tag :skip
    test "with other literal lists" do
      assert none() == [:foo, "bar"] <~> @list
      assert none() == [:foo] <~> @list
      assert none() == [:foo, :bar, :baz] <~> @list

      assert none() == @ilist <~> ["foo" | "baz"]
    end

    test "with unions works as expected" do
      assert @list == @list <~> (:foo <|> @list)
      assert @list == @list <~> (:foo <|> list())
      #assert none() == @list <~> (atom() <|> port())
#
      #assert @ilist == @ilist <~> (:foo <|> @ilist)
      #assert @ilist == @ilist <~> (:foo <|> %List{final: remote(String.t)})
      #assert none() == @ilist <~> (atom() <|> port())
    end

    @tag :skip
    test "with all other types is none" do
      TypeTest.Targets.except([list()])
      |> Enum.each(fn target ->
        assert none() == @list <~> target
        assert none() == target <~> @list
      end)
    end
  end
end
