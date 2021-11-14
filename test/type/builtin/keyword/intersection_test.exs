defmodule TypeTest.BuiltinKeyword.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  @foo_tuple %Type.Tuple{elements: [:foo, "bar"], fixed: true}
  @bar_tuple %Type.Tuple{elements: [:bar, "baz"], fixed: true}
  @baz_tuple %Type.Tuple{elements: [:baz, 3], fixed: true}

  describe "the intersection of keyword/0" do
    test "with any, list and keyword/0 is itself" do
      assert keyword() == keyword() <~> any()
      assert keyword() == keyword() <~> list()
      assert keyword() == keyword() <~> keyword()
    end

    test "with keyword/1 is the subtype" do
      assert keyword(:foo) == keyword() <~> keyword(:foo)
    end

    test "with valid keywords is valid keywords" do
      assert [] == keyword() <~> []
      assert [@foo_tuple] == keyword() <~> [@foo_tuple]
      assert [@foo_tuple, @baz_tuple] == keyword() <~> [@foo_tuple, @baz_tuple]
    end

    test "with none is none" do
      assert none() == keyword() <~> none()
    end

    test "with all other types is none" do
      [[], ["foo", "bar"], list()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == keyword() <~> target
      end)
    end
  end

  describe "the intersection of keyword/1" do
    test "with any, list and keyword/1 is itself" do
      assert keyword(binary()) == keyword(binary()) <~> any()
      assert keyword(binary()) == keyword(binary()) <~> list()
      assert keyword(binary()) == keyword(binary()) <~> keyword()
      assert keyword(binary()) == keyword(binary()) <~> keyword(binary())
    end

    test "with valid keywords is valid keywords" do
      assert [] == keyword(binary()) <~> []
      assert [@foo_tuple] == keyword(binary()) <~> [@foo_tuple]
      assert [@foo_tuple, @bar_tuple] == keyword(binary()) <~> [@foo_tuple, @bar_tuple]
    end

    test "with none is none" do
      assert none() == keyword(binary()) <~> none()
    end

    test "with all other types is none" do
      [[], ["foo", "bar"], list()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == keyword(binary()) <~> target
      end)
    end
  end
end
