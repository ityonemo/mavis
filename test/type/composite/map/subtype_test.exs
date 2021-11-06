defmodule TypeTest.TypeMap.SubtypeTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :subtype

  alias Type.Map
  import Type, only: :macros

  @any_map map()
  @empty_map %Map{}

  describe "the empty map" do
    test "is a subtype of itself and maps with optional types" do
      assert @empty_map in type(%{optional(:foo) => any()})
      assert @empty_map in type(%{integer() => any()})
      assert @empty_map in type(%{atom() => integer()})
    end

    test "is not a subtype of a map with a required type" do
      refute @empty_map in type(%{foo: any()})
    end

    test "is a subtype of the any map" do
      assert @empty_map in @any_map
    end
  end

  describe "for a map with a required type" do
    test "are subtypes for a broader value type" do
      assert type(%{foo: 1..10}) in type(%{foo: integer()})
    end

    test "is a subtype of the same map except optional" do
      assert type(%{foo: any()}) in type(%{optional(:foo) => any()})
    end

    test "is a subtype when the the optional version is broader" do
      assert type(%{foo: any()}) in type(%{atom() => any()})
    end

    test "is not a subtype when the target is narrower" do
      refute type(%{foo: any()}) in type(%{atom() => integer()})
    end

    test "is a subtype of the any map" do
      assert type(%{foo: any()}) in @any_map
    end
  end

  describe "maps with optional types" do
    test "are not subtypes of the same map except required" do
      refute type(%{optional(:foo) => any()}) in type(%{foo: any()})
    end

    test "is a subtype of the any map" do
      assert type(%{optional(:foo) => any()}) in @any_map
    end

    test "are not subtypes when their types are disjoint" do
      refute type(%{optional(:foo) => any()}) in type(%{optional(:bar) => any()})
    end
  end

  describe "the any map" do
    test "is a subtype of itself and any" do
      assert @any_map in @any_map
      assert @any_map in any()
    end

    test "is not generally a subtype of anything else" do
      TypeTest.Targets.except([@any_map])
      |> Enum.each(fn target ->
        refute @any_map in target
      end)
    end
  end
end
