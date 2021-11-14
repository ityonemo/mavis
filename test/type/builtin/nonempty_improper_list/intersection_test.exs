defmodule TypeTest.BuiltinNonemptyImproperList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of nonempty_improper_list/2" do
    test "with any, list, and nonempty_improper_list/2 is itself" do
      assert nonempty_improper_list(:foo, :bar) == nonempty_improper_list(:foo, :bar) <~> any()
      assert nonempty_improper_list(:foo, :bar) == nonempty_improper_list(:foo, :bar) <~> maybe_improper_list()
      assert nonempty_improper_list(:foo, :bar) == nonempty_improper_list(:foo, :bar) <~> maybe_improper_list(:foo, :bar)
      assert nonempty_improper_list(:foo, :bar) == nonempty_improper_list(:foo, :bar) <~> nonempty_maybe_improper_list()
      assert nonempty_improper_list(:foo, :bar) == nonempty_improper_list(:foo, :bar) <~> nonempty_maybe_improper_list(:foo, :bar)
      assert nonempty_improper_list(:foo, :bar) == nonempty_improper_list(:foo, :bar) <~> nonempty_improper_list(:foo, :bar)

    end

    test "with a literal list is itself" do
      assert [:foo | :bar] == nonempty_improper_list(:foo, :bar) <~> [:foo | :bar]
    end

    test "with a mismatching type is none" do
      assert none() == nonempty_improper_list(:foo, :bar) <~> [:bar | :bar]
    end

    test "with a mismatching terminator is none" do
      assert none() == nonempty_improper_list(:foo, :bar) <~> [:foo | :foo]
    end

    test "with a proper list is none" do
      assert none() == nonempty_improper_list(:foo, :bar) <~> [:foo]
    end

    test "with an empty list is none" do
      assert none() == nonempty_improper_list(:foo, :bar) <~> []
    end

    test "with none is none" do
      assert none() == nonempty_improper_list(:foo, :bar) <~> none()
    end

    test "with all other types is none" do
      []
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == nonempty_improper_list(:foo, :bar) <~> target
      end)
    end
  end
end
