defmodule TypeTest.BuiltinList.MaybeImproperListTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "maybe_improper_list/0" do
    test "is bigger than map and smaller types" do
      assert maybe_improper_list() > none()
      assert maybe_improper_list() > neg_integer()
      assert maybe_improper_list() > pos_integer()
      assert maybe_improper_list() > non_neg_integer()
      assert maybe_improper_list() > integer()
      assert maybe_improper_list() > float()
      assert maybe_improper_list() > atom()
      assert maybe_improper_list() > reference()
      assert maybe_improper_list() > function()
      assert maybe_improper_list() > port()
      assert maybe_improper_list() > pid()
      assert maybe_improper_list() > tuple()
      assert maybe_improper_list() > map()
    end

    test "is bigger than list and subtypes" do
      assert maybe_improper_list() > nonempty_charlist()
      assert maybe_improper_list() > charlist()
      assert maybe_improper_list() > iolist()
      assert maybe_improper_list() > nonempty_maybe_improper_list()
      assert maybe_improper_list() > nonempty_list()
      assert maybe_improper_list() > list()
    end

    test "is bigger than a specific maybe_improper_list" do
      assert maybe_improper_list() > maybe_improper_list(:foo, :bar)
    end

    test "is bigger than maybe_improper_list literals" do
      assert maybe_improper_list() > []
      assert maybe_improper_list() > [:foo]
      assert maybe_improper_list() > [:foo | :bar]
    end

    test "is smaller than other types" do
      assert maybe_improper_list() < bitstring()
      assert maybe_improper_list() < any()
    end
  end

  describe "maybe_improper_list/2" do
    test "is bigger than map and smaller types" do
      assert maybe_improper_list(:foo, :bar) > none()
      assert maybe_improper_list(:foo, :bar) > neg_integer()
      assert maybe_improper_list(:foo, :bar) > pos_integer()
      assert maybe_improper_list(:foo, :bar) > non_neg_integer()
      assert maybe_improper_list(:foo, :bar) > integer()
      assert maybe_improper_list(:foo, :bar) > float()
      assert maybe_improper_list(:foo, :bar) > atom()
      assert maybe_improper_list(:foo, :bar) > reference()
      assert maybe_improper_list(:foo, :bar) > function()
      assert maybe_improper_list(:foo, :bar) > port()
      assert maybe_improper_list(:foo, :bar) > pid()
      assert maybe_improper_list(:foo, :bar) > tuple()
      assert maybe_improper_list(:foo, :bar) > map()
    end

    test "is bigger than list subtypes" do
      assert maybe_improper_list(:foo, :bar) > nonempty_list(:foo)
      assert maybe_improper_list(:foo, :bar) > nonempty_maybe_improper_list(:foo, :bar)
      assert maybe_improper_list(:foo, :bar) > list(:foo)
    end

    test "is bigger than maybe_improper_list literals" do
      assert maybe_improper_list(:foo, :bar) > []
      assert maybe_improper_list(:foo, :bar) > [:foo]
      assert maybe_improper_list(:foo, :bar) > [:foo | :bar]
    end

    test "is smaller than a generic maybe_improper_list" do
      assert maybe_improper_list(:foo, :bar) < maybe_improper_list()
    end

    test "is smaller than other types" do
      assert maybe_improper_list(:foo, :bar) < bitstring()
      assert maybe_improper_list(:foo, :bar) < any()
    end
  end
end
