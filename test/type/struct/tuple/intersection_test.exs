defmodule TypeTest.TypeTuple.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  @anytuple tuple()
  @min_2_tuple tuple({any(), any(), ...})

  describe "minimum size tuple" do
    @tag :skip
    test "intersects with any and self" do
      assert @anytuple == @anytuple <~> any()
      assert @anytuple == @anytuple <~> @anytuple

      assert @min_2_tuple == @min_2_tuple <~> @min_2_tuple
    end

    @tag :skip
    test "adopts the greater minimum" do
      assert @min_2_tuple == @min_2_tuple <~> @anytuple
    end

    @tag :skip
    test "turns into its counterparty" do
      assert tuple({}) == @anytuple <~> tuple({})
      assert tuple({:foo}) == @anytuple <~> tuple({:foo})
      assert tuple({:foo, integer()}) ==
        @anytuple <~> tuple({:foo, integer()})

      assert tuple({:ok, integer()}) ==
        @min_2_tuple <~> tuple({:ok, integer()})

      assert tuple({:ok, binary(), integer()}) ==
        @min_2_tuple <~> tuple({:ok, binary(), integer()})
    end

    test "is none when the tuple is too small" do
      assert none() == tuple({any(), any(), any(), ...}) <~> tuple({:ok, integer()})
    end

    @tag :skip
    test "with unions works as expected" do
      assert tuple({}) == @anytuple <~> (tuple({}) <|> 1..10)
      assert none() == @anytuple <~> (atom() <|> port())

      assert none() == @min_2_tuple <~> (tuple({}) <|> 1..10)
      assert none() == @min_2_tuple <~> (atom() <|> port())
    end

    @tag :skip
    test "doesn't intersect with anything else" do
      TypeTest.Targets.except([@anytuple, tuple({})])
      |> Enum.each(fn target ->
        assert none() == @anytuple <~> target
      end)
    end
  end

  describe "tuples with defined elements" do
    @tag :skip
    test "intersect with the cartesian intersection" do
      assert tuple({:foo}) == tuple({:foo}) <~> tuple({atom()})
      assert tuple({:foo}) == tuple({atom()}) <~> tuple({:foo})

      assert tuple({:foo, 47}) ==
        tuple({:foo, integer()}) <~>
        tuple({atom(), 47})
      assert tuple({:foo, 47}) ==
        tuple({atom(), integer()}) <~>
        tuple({:foo, 47})
      assert tuple({:foo, 47}) ==
        tuple({:foo, 47}) <~>
        tuple({atom(), integer()})
    end

    @tag :skip
    test "a single mismatch yields none" do
      assert none() == tuple({:foo}) <~> tuple({:bar})
      assert none() == tuple({:foo, :bar}) <~> tuple({:bar, :bar})
      assert none() == tuple({:bar, :bar}) <~> tuple({:bar, :foo})
    end
  end
end
