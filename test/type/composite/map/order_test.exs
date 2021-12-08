defmodule TypeTest.TypeMap.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order
  @moduletag :map

  import Type, only: :macros

  use Type.Operators

  alias Type.Map

  @any_map map()
  @empty_map %Map{}

  describe "the any map type" do
    test "is bigger than other maps" do
      assert @any_map > @empty_map
      assert @any_map > type(%{foo: any()})
      assert @any_map > type(%{optional(:foo) => any()})
    end

    test "is smaller than a union containing it" do
      assert @any_map < nil <|> @any_map
    end
  end

  describe "the empty map type" do
    test "is smaller than other maps" do
      assert @empty_map < @any_map
      assert @empty_map < type(%{foo: any()})
      assert @empty_map < type(%{optional(:foo) => any()})
    end

    test "is smaller than a union of maps containing it" do
      assert @empty_map < @empty_map <|> type(%{foo: any()})
    end
  end

  describe "maps with no required keys" do
    @any_int_map type(%{optional(any()) => integer()})
    @int_any_map type(%{optional(integer()) => any()})
    @int_int_map type(%{optional(integer()) => integer()})

    test "maps with bigger preimages are bigger" do
      assert @any_map > @int_any_map
      assert @any_int_map > @int_int_map
      assert %Type.Map{optional: %{integer() => integer(), nil => nil}} > @int_int_map
    end

    test "maps with bigger postimages are bigger" do
      assert @any_map > @any_int_map
      assert @int_any_map > @int_int_map
      assert %Type.Map{optional: %{integer() => integer() <|> nil}} > @int_int_map
    end

    test "are bigger than the equivalent type with a required key" do
      assert type(%{optional(:foo) => any()}) > type(%{foo: any()})
    end
  end

  describe "for maps with optional and required keys" do
    test "is smaller than the same map without the required key" do
      assert type(%{optional(:foo) => any(), required(:bar) => any()}) <
        type(%{optional(:foo) => any()})

      assert type(%{optional(:foo) => any(), required(:bar) => any(), required(:baz) => any()}) <
        type(%{optional(:foo) => any(), optional(:bar) => any()})
    end
  end

  describe "for maps with required keys only" do
    test "more required keys are bigger" do
      assert type(%{foo: any(), bar: any()}) > type(%{foo: any()})
    end

    test "key order dominates" do
      assert type(%{foo: 1}) > type(%{bar: 2})
      assert type(%{required(:foo) => 1}) > type(%{required(1) => 2})
    end

    test "value order is triggered when the keys are the same" do
      assert type(%{foo: 2}) > type(%{foo: 1})
      assert type(%{required(1) => 2}) > type(%{required(1) => 1})
    end
  end
end
