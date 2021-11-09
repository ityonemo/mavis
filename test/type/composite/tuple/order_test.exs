defmodule TypeTest.TypeTuple.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  describe "a tuple" do
    test "is bigger than bottom and pid" do
      assert type({}) > none()
      assert type({}) > pid()
    end

    test "is bigger when it has more elements" do
      assert type({:foo}) > type({})
      assert type({:bar, :foo}) > type({:foo})
    end

    test "is bigger when its k'th element is more general" do
      assert type({any()}) > type({integer()})
      assert type({:foo, any()}) > type({:foo, integer()})
    end

    test "is smaller than a union containing it" do
      assert type({:foo}) < nil <|> type({:foo})
    end

    test "is smaller when it has fewer elements" do
      assert type({}) < type({:foo})
      assert type({:foo}) < type({:bar, :foo})
    end

    test "is smaller when its k'th element is less general" do
      assert type({integer()}) < type({any()})
      assert type({:foo, integer()}) < type({:foo, any()})
    end

    test "is smaller than bitstrings or top" do
      assert type({}) < %Type.Bitstring{size: 0, unit: 0}
      assert type({}) < any()
    end
  end

  describe "a tuple with 'any' elements" do
    test "is bigger than a tuple with defined elements" do
      assert tuple() > type({})
      assert tuple() > type({any()})
      assert tuple() > type({any(), any()})
    end
  end

  describe "a tuple with minimum arity" do
    test "is bigger than a tuple with a bigger minimum arity" do
      assert type({any(), any(), ...}) > type({any(), any(), any(), ...})
    end

    test "is bigger than any corresponding defined tuple" do
      assert type({any(), any(), ...}) > type({:ok, integer()})
    end
  end

end
