defmodule TypeTest.BuiltinNonEmptyMaybeImproperList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "nonempty_maybe_improper_list/0" do
    test "is bigger than map and smaller types" do
      assert nonempty_maybe_improper_list() > none()
      assert nonempty_maybe_improper_list() > neg_integer()
      assert nonempty_maybe_improper_list() > pos_integer()
      assert nonempty_maybe_improper_list() > non_neg_integer()
      assert nonempty_maybe_improper_list() > integer()
      assert nonempty_maybe_improper_list() > float()
      assert nonempty_maybe_improper_list() > atom()
      assert nonempty_maybe_improper_list() > reference()
      assert nonempty_maybe_improper_list() > function()
      assert nonempty_maybe_improper_list() > port()
      assert nonempty_maybe_improper_list() > pid()
      assert nonempty_maybe_improper_list() > tuple()
      assert nonempty_maybe_improper_list() > map()
    end

    test "is bigger than nonempty_maybe_improper_list literals" do
      assert nonempty_maybe_improper_list() > [:foo]
      assert nonempty_maybe_improper_list() > [:foo | :bar]
    end

    test "is bigger than nonempty_maybe_improper_list/2" do
      assert nonempty_maybe_improper_list() >
        nonempty_maybe_improper_list(:foo, :bar)
    end

    test "is smaller than list supertypes" do
      assert nonempty_maybe_improper_list() < maybe_improper_list()
    end

    test "is smaller than other types" do
      assert nonempty_maybe_improper_list() < bitstring()
      assert nonempty_maybe_improper_list() < any()
    end
  end

  describe "nonempty_maybe_improper_list/2" do
    test "is bigger than map and smaller types" do
      assert nonempty_maybe_improper_list(:foo, :bar) > none()
      assert nonempty_maybe_improper_list(:foo, :bar) > neg_integer()
      assert nonempty_maybe_improper_list(:foo, :bar) > pos_integer()
      assert nonempty_maybe_improper_list(:foo, :bar) > non_neg_integer()
      assert nonempty_maybe_improper_list(:foo, :bar) > integer()
      assert nonempty_maybe_improper_list(:foo, :bar) > float()
      assert nonempty_maybe_improper_list(:foo, :bar) > atom()
      assert nonempty_maybe_improper_list(:foo, :bar) > reference()
      assert nonempty_maybe_improper_list(:foo, :bar) > function()
      assert nonempty_maybe_improper_list(:foo, :bar) > port()
      assert nonempty_maybe_improper_list(:foo, :bar) > pid()
      assert nonempty_maybe_improper_list(:foo, :bar) > tuple()
      assert nonempty_maybe_improper_list(:foo, :bar) > map()
    end

    test "is bigger than nonempty_maybe_improper_list literals" do
      assert nonempty_maybe_improper_list(:foo, :bar) > [:foo]
      assert nonempty_maybe_improper_list(:foo, :bar) > [:foo | :bar]
    end

    test "is smaller than list supertypes" do
      assert nonempty_maybe_improper_list(:foo, :bar) < maybe_improper_list(:foo, :bar)
    end

    test "is smaller than other types" do
      assert nonempty_maybe_improper_list(:foo, :bar) < bitstring()
      assert nonempty_maybe_improper_list(:foo, :bar) < any()
    end
  end
end