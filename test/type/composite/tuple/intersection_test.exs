defmodule TypeTest.TypeTuple.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  @anytuple tuple()
  @min_2_tuple type({any(), any(), ...})

  describe "minimum size tuple" do
    test "intersects with any and self" do
      assert @anytuple == @anytuple <~> any()
      assert @anytuple == @anytuple <~> @anytuple

      assert @min_2_tuple == @min_2_tuple <~> @min_2_tuple
    end

    test "adopts the greater minimum" do
      assert @min_2_tuple == @min_2_tuple <~> @anytuple
    end

    test "turns into its counterparty" do
      assert type({}) == @anytuple <~> type({})
      assert type({:foo}) == @anytuple <~> type({:foo})
      assert type({:foo, integer()}) ==
        @anytuple <~> type({:foo, integer()})

      assert type({:ok, integer()}) ==
        @min_2_tuple <~> type({:ok, integer()})

      assert type({:ok, binary(), integer()}) ==
        @min_2_tuple <~> type({:ok, binary(), integer()})
    end

    test "is none when the tuple is too small" do
      assert none() == type({any(), any(), any(), ...}) <~> type({:ok, integer()})
    end

    test "with unions works as expected" do
      assert type({}) == @anytuple <~> (type({}) <|> 1..10)
      #assert none() == @anytuple <~> (atom() <|> port())
#
      #assert none() == @min_2_tuple <~> (type({}) <|> 1..10)
      #assert none() == @min_2_tuple <~> (atom() <|> port())
    end

    @tag :skip
    test "doesn't intersect with anything else" do
      TypeTest.Targets.except([@anytuple, type({})])
      |> Enum.each(fn target ->
        assert none() == @anytuple <~> target
      end)
    end
  end

  describe "tuples with defined elements" do
    test "intersect with the cartesian intersection" do
      assert type({:foo}) == type({:foo}) <~> type({atom()})
      assert type({:foo}) == type({atom()}) <~> type({:foo})

      assert type({:foo, 47}) ==
        type({:foo, integer()}) <~>
        type({atom(), 47})
      assert type({:foo, 47}) ==
        type({atom(), integer()}) <~>
        type({:foo, 47})
      assert type({:foo, 47}) ==
        type({:foo, 47}) <~>
        type({atom(), integer()})
    end

    test "a single mismatch yields none" do
      assert none() == type({:foo}) <~> type({:bar})
      assert none() == type({:foo, :bar}) <~> type({:bar, :bar})
      assert none() == type({:bar, :bar}) <~> type({:bar, :foo})
    end
  end
end
