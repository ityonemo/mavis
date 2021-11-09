defmodule TypeTest.TypeList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  alias Type.List

  describe "a nonempty true list" do
    test "is bigger than bottom and reference" do
      assert type([...]) > none()
      assert type([...]) > reference()
    end

    test "is bigger than a literal lists and lists which are a subclass" do
      assert type([...]) > []
      assert type([...]) > [:foo]
      assert type([...]) > nonempty_list(integer())
      # because the final is more general
      assert %List{type: any(), final: any()} >
        nonempty_list(any())
    end

    test "is smaller than a list which is a superclass" do
      assert nonempty_list(integer()) < type([...])
      assert nonempty_list(integer()) < list(integer())
      # because the final is more general
      assert type([...]) < %List{type: any(), final: any()}
    end

    test "is smaller than maybe-empty lists, empty list, bitstrings or top" do
      assert type([...]) < %Type.Bitstring{size: 0, unit: 0}
      assert type([...]) < any()
    end
  end

  describe "a nonempty false list" do
    test "is bigger than bottom and reference, and empty list" do
      assert list() > none()
      assert list() > reference()
      assert list() > []
    end

    test "is bigger than a list which is nonempty: true" do
      assert list(integer()) < type([...])
    end

    test "is bigger than a list which is a subclass" do
      assert list() > list(integer())
      # because the final is more general
      assert %List{type: any(), final: any()} > list()
    end

    @tag :skip
    # NB: currently broken because list seems to have [] before the nonempty list.
    test "is smaller than a union containing it" do
      assert list() < (nil <|> list())
    end

    test "is smaller than a list which is a superclass" do
      assert list(integer()) < list()
      # because the final is more general
      assert list() < %List{type: any(), final: any()}
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert list() < %Type.Bitstring{size: 0, unit: 0}
      assert list() < any()
    end
  end

end
