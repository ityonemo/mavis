defmodule TypeTest.TypeList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection
  @moduletag :skip # until Unions are done

  import Type, only: :macros

  alias Type.List

  @tag :skip
  test "go through the doctests and double check that list examples are there too"

  describe "normal list" do
    test "intersects with any and self" do
      assert list() == list() <~> any()
      assert list() == list() <~> list()
    end

    test "intersects with empty list as empty list" do
      assert [] == list() <~> []
    end

    @tag :skip
    test "intersects with another list with the intersection of types" do
      assert list(integer()) == list() <~> list(integer())
      assert list(47) == list(47) <~> list(integer())
    end

    @tag :skip
    test "with unions works as expected" do
      assert [] == list() <~> ([] <|> atom())
      assert none() == list() <~> (atom() <|> port())
    end

    @tag :skip
    test "doesn't intersect with anything else" do
      TypeTest.Targets.except([list(), [], ["foo", "bar"]])
      |> Enum.each(fn target ->
        assert none() == list() <~> target
      end)
    end
  end

  @tag :skip
  describe "nonempty list" do
    test "intersects with any and self" do
      assert list(...) == list() <~> list(...)
      assert list(...) == list(...) <~> list()
    end

    @tag :skip
    test "doesn't intersect with empty list" do
      assert none() == [] <~> list(...)
      assert none() == list(...) <~> []
    end
  end

  describe "list finals" do
    @tag :skip
    test "are reduced" do
      assert %List{final: pos_integer()} ==
        %List{final: pos_integer()} <~> %List{final: integer()}
      assert %List{final: pos_integer()} ==
        %List{final: integer()} <~> %List{final: pos_integer()}
    end
  end
end
