defmodule TypeTest.TypeMap.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Map

  @any builtin(:map)
  @any_map Map.build(%{@any => @any})

  describe "maps are first compared based on their global preimages" do
    test "any maps are bigger than other maps" do
      assert @any_map > %Map{} # empty map
      assert @any_map > Map.build(%{foo: @any}, %{})
      assert @any_map > Map.build(foo: @any)
    end

    test "empty maps are smaller than other maps" do
      assert %Map{} < Map.build(%{foo: @any}, %{})
      assert %Map{} < Map.build(%{builtin(:integer) => @any}, %{})
    end

    test "maps that have keys which are strict subtypes are smaller" do
      assert Map.build(foo: @any) < Map.build(%{bar: @any, foo: @any})
      assert Map.build(foo: @any) < Map.build(%{builtin(:atom) => @any})
      assert Map.build(%{1 => @any}) < Map.build(%{0..10 => @any})
      assert Map.build(%{1 => @any}) < Map.build(%{builtin(:pos_integer) => @any})
      assert Map.build(%{builtin(:pos_integer) => @any}) <
        Map.build(%{builtin(:integer) => @any})
    end

    test "keys are ordered without respect to being required or optional" do
      assert Map.build(%{foo: @any}, %{}) > Map.build(%{bar: @any}, %{})
      assert Map.build(foo: @any)         > Map.build(%{bar: @any}, %{})
      assert Map.build(%{foo: @any}, %{}) > Map.build(bar: @any)
      assert Map.build(foo: @any)         > Map.build(bar: @any)
    end
  end

  describe "a map with a required key" do
    test "is smaller than the same map with an optional key" do
      assert Map.build(%{foo: @any}, %{}) < Map.build(foo: @any)
      assert Map.build(%{foo: @any}, %{}) < Map.build(foo: builtin(:integer))
    end
  end
end
