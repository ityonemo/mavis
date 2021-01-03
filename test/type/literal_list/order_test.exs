defmodule TypeTest.LiteralList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  @list [:foo, :bar]

  describe "a literal list" do
    test "is bigger than bottom" do
      assert @list > none()
    end

    test "is bigger than a smaller integer" do
      assert @list > [:foo]
      assert @list > [:baz, :bar]
    end

    test "is smaller than a bigger integer" do
      assert @list < [:foo, :baz]
    end

    test "is smaller than list, which it is a subset of" do
      assert @list < list()
    end

    test "is smaller than things outside of list" do
      assert @list < bitstring()
      assert @list < any()
    end
  end
end
