defmodule TypeTest.BuiltinNonemptyCharList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "nonempty_charlist/0" do
    test "is bigger than map and smaller types" do
      assert nonempty_charlist() > none()
      assert nonempty_charlist() > neg_integer()
      assert nonempty_charlist() > pos_integer()
      assert nonempty_charlist() > non_neg_integer()
      assert nonempty_charlist() > integer()
      assert nonempty_charlist() > float()
      assert nonempty_charlist() > atom()
      assert nonempty_charlist() > reference()
      assert nonempty_charlist() > function()
      assert nonempty_charlist() > port()
      assert nonempty_charlist() > pid()
      assert nonempty_charlist() > tuple()
      assert nonempty_charlist() > map()
    end

    test "is bigger than nonempty_charlist literals" do
      assert nonempty_charlist() > [46]
    end

    test "is smaller than charlist supertypes" do
      assert nonempty_charlist() < charlist()
      assert nonempty_charlist() < iolist()
      assert nonempty_charlist() < nonempty_list()
      assert nonempty_charlist() < maybe_improper_list()
    end

    test "is smaller than other types" do
      assert nonempty_charlist() < bitstring()
      assert nonempty_charlist() < any()
    end
  end
end
