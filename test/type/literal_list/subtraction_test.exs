defmodule TypeTest.LiteralList.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :subtraction

  import Type, only: :macros

  alias Type.List

  @list [:foo, :bar]
  @ilist ["foo" | "bar"]

  describe "the subtraction from a literal list" do
    test "of itself, list and any is itself" do
      assert none() == @list - any()
      assert none() == @list - list()
      assert none() == @list - @list

      assert none() == @ilist - any()
      assert none() == @ilist - @ilist
    end

    test "of iolist literals is none" do
      assert none() == @ilist - iolist()
    end

    test "of correctly descriptive list types" do
      assert none() == @list - list(:foo <|> :bar)
      assert none() == @list - list(atom())

      assert none() == @ilist - %List{final: remote(String.t)}
      assert none() == @ilist - maybe_improper_list()
      assert none() == @ilist - nonempty_maybe_improper_list()
    end

    test "of wrong finals" do
      assert @ilist == @ilist - list()
      assert @list == @list - %List{final: remote(String.t)}
    end

    test "of other literal lists" do
      assert @list == @list - [:foo, "bar"]
      assert @list == @list - [:foo]
      assert @list == @list - [:foo, :bar, :baz]

      assert @ilist == @ilist - ["foo" | "baz"]
      assert @ilist == @ilist - ["foo", "bar"]
    end

    test "of unions works as expected" do
      assert none() == @list - (:foo <|> @list)
      assert none() == @list - (:foo <|> list())

      assert none() == @ilist - (:foo <|> @ilist)
      assert none() == @ilist - (:foo <|> %List{final: remote(String.t)})
    end

    test "of all other types is none" do
      TypeTest.Targets.except([list()])
      |> Enum.each(fn target ->
        assert @list == @list - target
        assert @ilist == @ilist - target
      end)
    end
  end
end
