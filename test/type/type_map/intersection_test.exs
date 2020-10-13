defmodule TypeTest.TypeMap.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  alias Type.Map

  @any builtin(:any)
  @any_map Map.build(%{@any => @any})

  describe "the empty map" do
    test "intersects with any and self" do
      assert %Map{} == %Map{} <~> builtin(:any)
      assert %Map{} == %Map{} <~> %Map{}
    end
  end

  describe "the arbitrary map" do
    test "intersects with any and self" do
      assert @any_map == @any_map <~> builtin(:any)
      assert @any_map == @any_map <~> @any_map
    end

    test "intersects with no other type" do
      TypeTest.Targets.except([@any_map])
      |> Enum.each(fn target ->
        assert builtin(:none) == @any_map <~> target
      end)
    end
  end

  describe "a map with a single optional type" do
    test "intersects with empty map" do
      int_any_map = Map.build(%{builtin(:integer) => @any})

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

      map1 = Map.build(%{-10..2 => builtin(:atom),
                         3..5 => builtin(:integer),
                         6..7 => builtin(:atom)})
      map2 = Map.build(%{builtin(:pos_integer) => builtin(:atom)})

      assert Map.build(%{1..2 => builtin(:atom),
                         6..7 => builtin(:atom)}) == map1 <~> map2
    end
  end

  @foo_int Map.build(%{foo: builtin(:integer)}, %{})
  describe "maps with required types" do
    test "intersect with the intersection of the values" do
      assert Map.build(%{foo: 3..5}, %{}) ==
        Map.build(%{foo: 1..5}, %{}) <~>
        Map.build(%{foo: 3..8}, %{})
    end

    test "intersect with none if they don't match" do
      assert builtin(:none) == @foo_int <~> Map.build(%{bar: builtin(:integer)}, %{})
    end

    test "intersect with none if their value types don't match" do
      assert builtin(:none) == @foo_int <~> Map.build(%{foo: builtin(:atom)}, %{})
    end
  end

  describe "maps with matching required and optional types" do
    test "convert optionals to required" do
      assert @foo_int == @foo_int <~> Map.build(foo: builtin(:integer))
    end

    test "intersect optional key types, if necessary" do
      assert @foo_int == @foo_int <~> Map.build(%{builtin(:atom) => builtin(:integer)})
    end

    test "intersect value types" do
      assert Map.build(%{foo: 1..10}, %{}) ==
        @foo_int <~> Map.build(%{builtin(:atom) => 1..10})
    end

    test "intersect with none if it's impossible to construct the required" do
      assert builtin(:none) ==
        @foo_int <~> Map.build(%{builtin(:integer) => builtin(:integer)})
    end
  end
end
