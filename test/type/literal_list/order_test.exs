defmodule TypeTest.LiteralFloat.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  @list [:foo, :bar]

  describe "a literal list" do
    test "is bigger than bottom" do
      assert literal(@list) > none()
    end

    test "is bigger than a smaller integer" do
      assert literal(@list) > literal([:foo])
      assert literal(@list) > literal([:baz, :bar])
    end

    test "is smaller than a bigger integer" do
      assert literal(@list) < literal([:foo, :baz])
    end

    test "is smaller than list, which it is a subset of" do
      assert literal(@list) < list()
    end

    test "is smaller than things outside of list" do
      assert literal(@list) < bitstring()
      assert literal(@list) < any()
    end
  end
end
