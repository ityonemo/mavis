defmodule TypeTest.BuiltinCharlist.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of charlist" do
    test "with any, list, and charlist is itself" do
      assert charlist() == charlist() <~> any()
      assert charlist() == charlist() <~> list()
      assert charlist() == charlist() <~> charlist()
    end

    test "with a literal list is itself" do
      assert [] == charlist() <~> []
      assert [47] == charlist() <~> [47]
    end

    test "with a list of bytes is a list of bytes" do
      assert type([byte()]) == charlist() <~> type([byte()])
    end

    test "an improper charlist is not supported" do
      assert none() == charlist() <~> [47 | 42]
    end

    test "with none is none" do
      assert none() == charlist() <~> none()
    end

    test "with all other types is none" do
      [[], list()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == charlist() <~> target
      end)
    end
  end
end
