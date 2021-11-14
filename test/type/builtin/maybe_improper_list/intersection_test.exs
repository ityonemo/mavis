defmodule TypeTest.BuiltinMaybeImproperList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of maybe_improper_list/2" do
    test "with any, maybe_improper_list and maybe_improper_list/2 is itself" do
      assert maybe_improper_list(:foo, :bar) == maybe_improper_list(:foo, :bar) <~> any()
      assert maybe_improper_list(:foo, :bar) == maybe_improper_list(:foo, :bar) <~> maybe_improper_list(:foo, :bar)
    end

    test "with list is the list type" do
      assert list(:foo) == maybe_improper_list(:foo, :bar) <~> list()
    end

    test "with empty list is empty list" do
      assert [] == maybe_improper_list(:foo, :bar) <~> []
    end

    test "with an example is itself" do
      assert [:foo] == maybe_improper_list(:foo, :bar) <~> [:foo]
      assert [:foo | :bar] == maybe_improper_list(:foo, :bar) <~> [:foo | :bar]
    end

    test "with a list of wrong type is empty list" do
      assert [] == maybe_improper_list(:foo, :bar) <~> list(:bar)
    end

    test "with a bad example literal is none" do
      assert none() == maybe_improper_list(:foo, :bar) <~> [:bar]
    end

    test "with a bad final is none" do
      assert none() == maybe_improper_list(:foo, :bar) <~> [:foo | :foo]
    end

    test "with none is none" do
      assert none() == maybe_improper_list(:foo, :bar) <~> none()
    end

    test "with all other types is none" do
      [[], list()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == maybe_improper_list(:foo, :bar) <~> target
      end)
    end
  end
end
