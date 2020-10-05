defmodule TypeTest.TypeMap.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  doctest Type.Map

  @moduletag :intersection

  import Type, only: [builtin: 1]

  alias Type.Map

  @any builtin(:any)
  @any_map %Map{optional: [{@any, @any}]}

  describe "the empty map" do
    test "intersects with any and self" do
      assert %Map{} == Type.intersection(%Map{}, builtin(:any))
      assert %Map{} == Type.intersection(%Map{}, %Map{})
    end
  end

  describe "the arbitrary map" do
    test "intersects with any and self" do
      assert @any_map == Type.intersection(@any_map, builtin(:any))
      assert @any_map == Type.intersection(@any_map, @any_map)
    end

    test "intersects with no other type" do
      TypeTest.Targets.except([@any_map])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(@any_map, target)
      end)
    end
  end

  describe "a map with a single optional type" do
    test "intersects with empty map" do
      int_any_map = %Map{optional: [{builtin(:integer), @any}]}

      assert int_any_map = Type.intersection(int_any_map, @any_map)
      assert int_any_map = Type.intersection(int_any_map, int_any_map)
    end
  end

  test "a complex map example" do
    # These maps can take integers.
    # Map 1:      0   3       5      7
    # <-----------|---|-------|------|-->
    #    atom         |<-int->| atom |
    # Map 2:      0
    # <-----------|---------------->
    #               atom
    #
    # intersection should be 0..2 => atom, 6..7 => atom

    map1 = %Map{optional: [{-10..2, builtin(:atom)},
                           {3..5, builtin(:integer)},
                           {6..7, builtin(:atom)}]}
    map2 = %Map{optional: [{builtin(:pos_integer), builtin(:atom)}]}

    assert %Map{optional: [{1..2, builtin(:atom)},
                           {6..7, builtin(:atom)}]} ==
             Type.intersection(map1, map2)
  end

  test "map unions"

end
