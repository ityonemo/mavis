defmodule TypeTest.BuiltinNonEmptyList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "nonempty_list/0" do
    test "is bigger than map and smaller types" do
      assert nonempty_list() > none()
      assert nonempty_list() > neg_integer()
      assert nonempty_list() > pos_integer()
      assert nonempty_list() > non_neg_integer()
      assert nonempty_list() > integer()
      assert nonempty_list() > float()
      assert nonempty_list() > atom()
      assert nonempty_list() > reference()
      assert nonempty_list() > function()
      assert nonempty_list() > port()
      assert nonempty_list() > pid()
      assert nonempty_list() > tuple()
      assert nonempty_list() > map()
    end

    test "is bigger than nonempty_list literals" do
      assert nonempty_list() > [:foo]
    end

    test "is smaller than list supertypes" do
      assert nonempty_list() < list()
      assert nonempty_list() < maybe_improper_list()
    end

    test "is smaller than other types" do
      assert nonempty_list() < bitstring()
      assert nonempty_list() < any()
    end
  end

  describe "nonempty_list/1" do
    test "a"
  end
end
