defmodule TypeTest.BuiltinNonemptyList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of nonempty_list/1" do
    test "with any, list, and nonempty_list is itself" do
      assert nonempty_list(:foo) == nonempty_list(:foo) <~> any()
      assert nonempty_list(:foo) == nonempty_list(:foo) <~> list()
      assert nonempty_list(:foo) == nonempty_list(:foo) <~> nonempty_list(:foo)
    end

    test "with a literal list is itself" do
      assert [:foo, :foo] == nonempty_list(:foo) <~> [:foo, :foo]
    end

    test "with a mismatching type is none" do
      assert none() == nonempty_list(:foo) <~> [:bar]
    end

    test "with an improper list is none" do
      assert none() == nonempty_list(:foo) <~> [:foo | :foo]
    end

    test "with an empty list is none" do
      assert none() == nonempty_list(:foo) <~> []
    end

    test "with none is none" do
      assert none() == nonempty_list(:foo) <~> none()
    end

    test "with all other types is none" do
      [list()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == nonempty_list(:foo) <~> target
      end)
    end
  end

  describe "the intersection of nonempty_list/0" do
    test "with any, list, and nonempty_list is itself" do
      assert nonempty_list() == nonempty_list() <~> any()
      assert nonempty_list() == nonempty_list() <~> list()
      assert nonempty_list() == nonempty_list() <~> nonempty_list()
    end

    test "with a literal list is itself" do
      assert [:foo, :foo] == nonempty_list() <~> [:foo, :foo]
    end

    test "with an improper list is none" do
      assert none() == nonempty_list() <~> [:foo | :foo]
    end

    test "with an empty list is none" do
      assert none() == nonempty_list() <~> []
    end

    test "with none is none" do
      assert none() == nonempty_list() <~> none()
    end

    test "with all other types is none" do
      [list(), ["foo", "bar"]]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == nonempty_list() <~> target
      end)
    end
  end
end
