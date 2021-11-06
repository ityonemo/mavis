defmodule TypeTest.TypeMap.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  alias Type.Map

  @any_map map()

  describe "maps are first compared based on their global preimages" do
    test "any maps are bigger than other maps" do
      assert @any_map > %Map{} # empty map
      assert @any_map > type(%{foo: any()})
      assert @any_map > type(%{optional(:foo) => any()})
    end

    test "is smaller than a union containing it" do
      assert @any_map < nil <|> @any_map
    end

    test "empty maps are smaller than other maps" do
      assert %Map{} < type(%{foo: any()})
      assert %Map{} < type(%{integer() => any()})
    end

    test "maps that have keys which are strict subtypes are smaller" do
      assert type(%{optional(:foo) => any()}) < type(%{bar: any(), foo: any()})
      assert type(%{optional(:foo) => any()}) < type(%{atom() => any()})
      assert type(%{1 => any()}) < type(%{0..10 => any()})
      assert type(%{1 => any()}) < type(%{pos_integer() => any()})
      assert type(%{pos_integer() => any()}) < type(%{integer() => any()})
    end

    test "keys are ordered without respect to being required or optional" do
      assert type(%{optional(:foo) => any()}) > type(%{bar: any()})
      assert type(%{optional(:foo) => any()}) > type(%{optional(:bar) => any()})
      assert type(%{foo: any()}) > type(%{bar: any()})
      assert type(%{foo: any()}) > type(%{optional(:bar) => any()})
    end
  end

  describe "a map with a required key" do
    test "is smaller than the same map with an optional key" do
      assert type(%{foo: any()}) < type(%{optional(:foo) => any()})
      assert type(%{foo: any()}) < type(%{optional(:foo) => integer()})
    end
  end
end
