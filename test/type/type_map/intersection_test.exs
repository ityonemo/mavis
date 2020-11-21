defmodule TypeTest.TypeMap.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Map

  @any any()
  @any_map map()

  describe "the empty map" do
    test "intersects with any and self" do
      assert %Map{} == %Map{} <~> any()
      assert %Map{} == %Map{} <~> %Map{}
    end
  end

  describe "the arbitrary map" do
    test "intersects with any and self" do
      assert @any_map == @any_map <~> any()
      assert @any_map == @any_map <~> @any_map
    end

    test "intersects with no other type" do
      TypeTest.Targets.except([@any_map])
      |> Enum.each(fn target ->
        assert none() == @any_map <~> target
      end)
    end
  end

  describe "a map with a single optional type" do
    test "intersects with empty map" do
      int_any_map = map(%{integer() => @any})

      assert int_any_map == int_any_map <~> @any_map
      assert int_any_map == int_any_map <~> int_any_map
    end
  end

  describe "a complicated optional type example" do
    test "segments its matches correctly" do
      # These maps can take integers.
      # Map 1:      0   3       5      7
      # <-----------<|>---<|>-------<|>------<|>-->
      #    atom         <|><-int-><|> atom <|>
      # Map 2:      0
      # <-----------<|>---------------->
      #               atom
      #
      # intersection should be 0..2 => atom, 6..7 => atom

      map1 = map(%{-10..2 => atom(),
                     3..5 => integer(),
                     6..7 => atom()})
      map2 = map(%{pos_integer() => atom()})

      assert map(%{1..2 => atom(),
                   6..7 => atom()}) == map1 <~> map2
    end
  end

  @foo_int map(%{foo: integer()})
  describe "maps with required types" do
    test "intersect with the intersection of the values" do
      assert map(%{foo: 3..5}) == map(%{foo: 1..5}) <~> map(%{foo: 3..8})
    end

    test "intersect with none if they don't match" do
      assert none() == @foo_int <~> map(%{bar: integer()})
    end

    test "intersect with none if their value types don't match" do
      assert none() == @foo_int <~> map(%{foo: atom()})
    end
  end

  describe "maps with matching required and optional types" do
    test "convert optionals to required" do
      assert @foo_int == @foo_int <~> map(%{optional(:foo) => integer()})
    end

    test "intersect optional key types, if necessary" do
      assert @foo_int == @foo_int <~> map(%{atom() => integer()})
    end

    test "intersect value types" do
      assert map(%{foo: 1..10}) == @foo_int <~> map(%{atom() => 1..10})
    end

    test "intersect with none if it's impossible to construct the required" do
      assert none() ==
        @foo_int <~> map(%{integer() => integer()})
    end
  end
end
