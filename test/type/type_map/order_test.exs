defmodule TypeTest.TypeMap.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.Map

  @any builtin(:any)
  @any_map builtin(:map)

  describe "maps are first compared based on their global preimages" do
    test "any maps are bigger than other maps" do
      assert @any_map > %Map{} # empty map
      assert @any_map > map(%{foo: @any})
      assert @any_map > map(%{optional(:foo) => @any})
    end

    test "is smaller than a union containing it" do
      assert @any_map < nil <|> @any_map
    end

    test "empty maps are smaller than other maps" do
      assert %Map{} < map(%{foo: @any})
      assert %Map{} < map(%{builtin(:integer) => @any})
    end

    test "maps that have keys which are strict subtypes are smaller" do
      assert map(%{optional(:foo) => @any}) < map(%{bar: @any, foo: @any})
      assert map(%{optional(:foo) => @any}) < map(%{builtin(:atom) => @any})
      assert map(%{1 => @any}) < map(%{0..10 => @any})
      assert map(%{1 => @any}) < map(%{builtin(:pos_integer) => @any})
      assert map(%{builtin(:pos_integer) => @any}) < map(%{builtin(:integer) => @any})
    end

    test "keys are ordered without respect to being required or optional" do
      assert map(%{optional(:foo) => @any}) > map(%{bar: @any})
      assert map(%{optional(:foo) => @any}) > map(%{optional(:bar) => @any})
      assert map(%{foo: @any}) > map(%{bar: @any})
      assert map(%{foo: @any}) > map(%{optional(:bar) => @any})
    end
  end

  describe "a map with a required key" do
    test "is smaller than the same map with an optional key" do
      assert map(%{foo: @any}) < map(%{optional(:foo) => @any})
      assert map(%{foo: @any}) < map(%{optional(:foo) => builtin(:integer)})
    end
  end
end
