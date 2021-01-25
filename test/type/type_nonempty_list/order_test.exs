defmodule TypeTest.TypeNonemptyList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.NonemptyList

  describe "a nonempty true list" do
    test "is bigger than bottom and reference" do
      assert list(...) > none()
      assert list(...) > reference()
    end

    test "is bigger than a list which is a subclass" do
      assert list(...) > list(integer(), ...)
      # because the final is more general
      assert %NonemptyList{type: any(), final: any()} >
        list(any(), ...)
    end

    test "is smaller than a list which is a superclass" do
      assert list(integer(), ...) < list(...)
      assert list(integer(), ...) < list(integer())
      # because the final is more general
      assert list(...) < %NonemptyList{type: any(), final: any()}
    end

    test "is smaller than maybe-empty lists, empty list, bitstrings or top" do
      assert list(...) < []
      assert list(...) < list(integer())
      assert list(...) < %Type.Bitstring{size: 0, unit: 0}
      assert list(...) < any()
    end
  end

  describe "a nonempty false list" do
    test "is bigger than bottom and reference, and empty list" do
      assert list() > none()
      assert list() > reference()
      assert list() > []
    end

    test "is bigger than a list which is nonempty: true" do
      assert list(integer()) > list(any(), ...)
    end

    test "is bigger than a list which is a subclass" do
      assert list() > list(integer())
      # because the final is more general
      assert %NonemptyList{type: any(), final: any()} > list()
    end

    test "is smaller than a union containing it" do
      assert list() < (nil <|> list())
    end

    test "is smaller than a list which is a superclass" do
      assert list(integer()) < list()
      # because the final is more general
      assert list() < %NonemptyList{type: any(), final: any()}
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert list() < %Type.Bitstring{size: 0, unit: 0}
      assert list() < any()
    end
  end

end
