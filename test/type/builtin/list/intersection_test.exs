defmodule TypeTest.BuiltinList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of list/0" do
    test "with any, list and list/0 is itself" do
      assert list() == list() <~> any()
      assert list() == list() <~> list()
    end

    test "with list/1 is the subtype" do
      assert list(:foo) == list() <~> list(:foo)
    end

    test "with other specialized lists is them" do
      assert iolist() == list() <~> iolist()
      assert iolist() == list() <~> iodata()
      assert keyword() == list() <~> keyword()
      assert charlist() == list() <~> charlist()
    end

    test "with valid keywords is valid keywords" do
      assert [] == list() <~> []
    end

    test "with an improper list is none" do
      assert none() == list() <~> [:foo | :bar]
    end

    test "with none is none" do
      assert none() == list() <~> none()
    end

    test "with all other types is none" do
      [[], ["foo", "bar"], list()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == list() <~> target
      end)
    end
  end

  describe "the intersection of list/1" do
    test "with any, list and list/1 is itself" do
      assert list(binary()) == list(binary()) <~> any()
      assert list(binary()) == list(binary()) <~> list()
      assert list(binary()) == list(binary()) <~> list(binary())
    end

    test "with valid keywords is valid keywords" do
      assert [] == list(binary()) <~> []
      assert ["foo"] == list(binary()) <~> ["foo"]
      assert ["foo", "bar"] == list(binary()) <~> ["foo", "bar"]
    end

    test "with a mismatching type is none" do
      assert none() == list(binary()) <~> [:foo]
    end

    test "with an improper list is none" do
      assert none() == list(binary()) <~> ["foo" | "bar"]
    end

    test "with none is none" do
      assert none() == list(binary()) <~> none()
    end

    test "with all other types is none" do
      [[], ["foo", "bar"], list()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == list(binary()) <~> target
      end)
    end
  end
end
