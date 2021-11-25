defmodule TypeTest.BuiltinNonemptyImproperList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "nonempty_improper_list/0" do
    test "is bigger than map and smaller types" do
      assert nonempty_improper_list(:foo, :bar) > none()
      assert nonempty_improper_list(:foo, :bar) > neg_integer()
      assert nonempty_improper_list(:foo, :bar) > pos_integer()
      assert nonempty_improper_list(:foo, :bar) > non_neg_integer()
      assert nonempty_improper_list(:foo, :bar) > integer()
      assert nonempty_improper_list(:foo, :bar) > float()
      assert nonempty_improper_list(:foo, :bar) > atom()
      assert nonempty_improper_list(:foo, :bar) > reference()
      assert nonempty_improper_list(:foo, :bar) > function()
      assert nonempty_improper_list(:foo, :bar) > port()
      assert nonempty_improper_list(:foo, :bar) > pid()
      assert nonempty_improper_list(:foo, :bar) > tuple()
      assert nonempty_improper_list(:foo, :bar) > map()
    end

    test "is bigger than nonempty_improper_list literals" do
      assert nonempty_improper_list(:foo, :bar) > [:foo | :bar]
    end

    test "is smaller than supertypes" do
      assert nonempty_improper_list(:foo, :bar) < maybe_improper_list()
    end

    test "is smaller than other types" do
      assert nonempty_improper_list(:foo, :bar) < bitstring()
      assert nonempty_improper_list(:foo, :bar) < any()
    end
  end

  describe "nonempty_improper_list/2" do
    test "a"
  end
end
