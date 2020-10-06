defmodule TypeTest.TypeMap.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Map

  @any builtin(:map)
  @any_map %Map{optional: [{@any, @any}]}

  describe "maps are first compared based on their global preimages" do
    test "any maps are bigger than other maps" do
      assert @any_map > %Map{} # empty map
      assert @any_map > %Map{required: [foo: @any]}
      assert @any_map > %Map{optional: [foo: @any]}
    end

    test "empty maps are smaller than other maps" do
      assert %Map{} < %Map{required: [foo: @any]}
      assert %Map{} < %Map{required: [{builtin(:integer), @any}]}
    end

    test "maps that have keys which are strict subtypes are smaller" do
      assert %Map{optional: [foo: @any]} < %Map{optional: [bar: @any, foo: @any]}
      assert %Map{optional: [foo: @any]} < %Map{optional: [{builtin(@atom), @any}]}
      assert %Map{optional: [{1, @any}]} < %Map{optional: [{0..10, @any}]}
      assert %Map{optional: [{1, @any}]} < %Map{optional: [{builtin(:pos_integer), @any}]}
      assert %Map{optional: [{builtin(:pos_integer), @any}]} < %Map{optional: [{builtin(:integer), @any}]}
    end

    test "keys are ordered without respect to being required or optional" do
      assert %Map{required: [foo: @any]} > %Map{required: [bar: @any]}
      assert %Map{optional: [foo: @any]} > %Map{required: [bar: @any]}
      assert %Map{required: [foo: @any]} > %Map{optional: [bar: @any]}
      assert %Map{optional: [foo: @any]} > %Map{optional: [bar: @any]}
    end
  end

  describe "a map with a required key" do
    test "is smaller than the same map with an optional key" do
      assert %Map{required: [foo: @any]} < %Map{optional: [foo: @any]}
      assert %Map{required: [foo: @any]} < %Map{optional: [foo: builtin(:integer)]}
    end
  end
end
