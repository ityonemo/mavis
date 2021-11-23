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
    test "a"
  end
end
