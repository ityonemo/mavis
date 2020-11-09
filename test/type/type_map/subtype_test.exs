defmodule TypeTest.TypeMap.SubtypeTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :subtype

  alias Type.Map
  import Type, only: :macros

  @any builtin(:any)
  @any_map builtin(:map)
  @empty_map %Map{}

  describe "the empty map" do
    test "is a subtype of itself and maps with optional types" do
      assert @empty_map in map(%{optional(:foo) => @any})
      assert @empty_map in map(%{builtin(:integer) => @any})
      assert @empty_map in map(%{builtin(:atom) => builtin(:integer)})
    end

    test "is not a subtype of a map with a required type" do
      refute @empty_map in map(%{foo: @any})
    end

    test "is a subtype of the any map" do
      assert @empty_map in @any_map
    end
  end

  describe "for a map with a required type" do
    test "are subtypes for a broader value type" do
      assert map(%{foo: 1..10}) in map(%{foo: builtin(:integer)})
    end

    test "is a subtype of the same map except optional" do
      assert map(%{foo: @any}) in map(%{optional(:foo) => @any})
    end

    test "is a subtype when the the optional version is broader" do
      assert map(%{foo: @any}) in map(%{builtin(:atom) => @any})
    end

    test "is not a subtype when the target is narrower" do
      refute map(%{foo: @any}) in map(%{builtin(:atom) => builtin(:integer)})
    end

    test "is a subtype of the any map" do
      assert map(%{foo: @any}) in @any_map
    end
  end

  describe "maps with optional types" do
    test "are not subtypes of the same map except required" do
      refute map(%{optional(:foo) => @any}) in map(%{foo: @any})
    end

    test "is a subtype of the any map" do
      assert map(%{optional(:foo) => @any}) in @any_map
    end

    test "are not subtypes when their types are disjoint" do
      refute map(%{optional(:foo) => @any}) in map(%{optional(:bar) => @any})
    end
  end

  describe "the any map" do
    test "is a subtype of itself and any" do
      assert @any_map in @any_map
      assert @any_map in @any
    end

    test "is not generally a subtype of anything else" do
      TypeTest.Targets.except([@any_map])
      |> Enum.each(fn target ->
        refute @any_map in target
      end)
    end
  end
end
