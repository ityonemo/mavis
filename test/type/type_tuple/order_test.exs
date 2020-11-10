defmodule TypeTest.TypeTuple.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "a tuple" do
    test "is bigger than bottom and pid" do
      assert tuple({}) > builtin(:none)
      assert tuple({}) > builtin(:pid)
    end

    test "is bigger when it has more elements" do
      assert tuple({:foo}) > tuple({})
      assert tuple({:bar, :foo}) > tuple({:foo})
    end

    test "is bigger when its k'th element is more general" do
      assert tuple({builtin(:any)}) > tuple({builtin(:integer)})
      assert tuple({:foo, builtin(:any)}) > tuple({:foo, builtin(:integer)})
    end

    test "is smaller than a union containing it" do
      assert tuple({:foo}) < nil <|> tuple({:foo})
    end

    test "is smaller when it has fewer elements" do
      assert tuple({}) < tuple({:foo})
      assert tuple({:foo}) < tuple({:bar, :foo})
    end

    test "is smaller when its k'th element is less general" do
      assert tuple({builtin(:integer)}) < tuple({builtin(:any)})
      assert tuple({:foo, builtin(:integer)}) < tuple({:foo, builtin(:any)})
    end

    test "is smaller than bitstrings or top" do
      assert tuple({}) < %Type.Bitstring{size: 0, unit: 0}
      assert tuple({}) < builtin(:any)
    end
  end

  describe "a tuple with 'any' elements" do
    test "is bigger than a tuple with defined elements" do
      assert builtin(:tuple) > tuple({})
      assert builtin(:tuple) > tuple({builtin(:any)})
      assert builtin(:tuple) > tuple({builtin(:any), builtin(:any)})
    end
  end

end
