defmodule TypeTest.BuiltinList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "list/0" do
    test "is bigger than map and smaller types" do
      assert list() > none()
      assert list() > neg_integer()
      assert list() > pos_integer()
      assert list() > non_neg_integer()
      assert list() > integer()
      assert list() > float()
      assert list() > atom()
      assert list() > reference()
      assert list() > function()
      assert list() > port()
      assert list() > pid()
      assert list() > tuple()
      assert list() > map()
    end

    test "is bigger than a specific list" do
      assert list() > list(:foo)
    end

    test "is bigger than list subtypes" do
      assert list() > nonempty_charlist()
      assert list() > charlist()
      assert list() > iolist()
      assert list() > nonempty_list()
    end

    test "is bigger than list literals" do
      assert list() > []
      assert list() > [:foo]
    end

    test "is smaller than generalized maybe_improper_list" do
      assert list() < maybe_improper_list()
    end

    test "is smaller than other types" do
      assert list() < bitstring()
      assert list() < any()
    end
  end

  describe "list/1" do
    test "is bigger than map and smaller types" do
      assert list(:foo) > none()
      assert list(:foo) > neg_integer()
      assert list(:foo) > pos_integer()
      assert list(:foo) > non_neg_integer()
      assert list(:foo) > integer()
      assert list(:foo) > float()
      assert list(:foo) > atom()
      assert list(:foo) > reference()
      assert list(:foo) > function()
      assert list(:foo) > port()
      assert list(:foo) > pid()
      assert list(:foo) > tuple()
      assert list(:foo) > map()
    end

    test "is bigger than list subtypes" do
      assert list(:foo) > nonempty_list(:foo)
    end

    test "is bigger than list literals" do
      assert list(:foo) > [:foo]
    end

    test "is smaller than generalized list types" do
      assert list(:foo) < list()
      assert list(:foo) < maybe_improper_list()
    end

    test "is smaller than other types" do
      assert list(:foo) < bitstring()
      assert list(:foo) < any()
    end
  end
end
