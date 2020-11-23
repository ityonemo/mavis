defmodule TypeTest.TypeTuple.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "a tuple" do
    test "is bigger than bottom and pid" do
      assert tuple({}) > none()
      assert tuple({}) > pid()
    end

    test "is bigger when it has more elements" do
      assert tuple({:foo}) > tuple({})
      assert tuple({:bar, :foo}) > tuple({:foo})
    end

    test "is bigger when its k'th element is more general" do
      assert tuple({any()}) > tuple({integer()})
      assert tuple({:foo, any()}) > tuple({:foo, integer()})
    end

    test "is smaller than a union containing it" do
      assert tuple({:foo}) < nil <|> tuple({:foo})
    end

    test "is smaller when it has fewer elements" do
      assert tuple({}) < tuple({:foo})
      assert tuple({:foo}) < tuple({:bar, :foo})
    end

    test "is smaller when its k'th element is less general" do
      assert tuple({integer()}) < tuple({any()})
      assert tuple({:foo, integer()}) < tuple({:foo, any()})
    end

    test "is smaller than bitstrings or top" do
      assert tuple({}) < %Type.Bitstring{size: 0, unit: 0}
      assert tuple({}) < any()
    end
  end

  describe "a tuple with 'any' elements" do
    test "is bigger than a tuple with defined elements" do
      assert tuple() > tuple({})
      assert tuple() > tuple({any()})
      assert tuple() > tuple({any(), any()})
    end
  end

  describe "a tuple with minimum arity" do
    test "is bigger than a tuple with a bigger minimum arity" do
      assert tuple({any(), any(), ...}) > tuple({any(), any(), any(), ...})
    end

    test "is bigger than any corresponding defined tuple" do
      assert tuple({any(), any(), ...}) > tuple({:ok, integer()})
    end
  end

end
