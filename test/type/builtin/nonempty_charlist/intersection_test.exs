defmodule TypeTest.BuiltinNonemptyCharlist.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of nonempty_charlist" do
    test "with any, list, and nonempty_charlist is itself" do
      assert nonempty_charlist() == nonempty_charlist() <~> any()
      assert nonempty_charlist() == nonempty_charlist() <~> list()
      assert nonempty_charlist() == nonempty_charlist() <~> nonempty_list()
      assert nonempty_charlist() == nonempty_charlist() <~> nonempty_charlist()
    end

    test "with a literal list is itself" do
      assert [47] == nonempty_charlist() <~> [47]
    end

    test "with a list of bytes is a list of bytes" do
      assert type([byte, ...]) == nonempty_charlist() <~> type([byte])
    end

    test "with an empty list is none" do
      assert none() == nonempty_charlist() <~> []
    end

    test "an improper nonempty_charlist is none" do
      assert none() == nonempty_charlist() <~> [47 | 42]
    end

    test "with none is none" do
      assert none() == nonempty_charlist() <~> none()
    end

    test "with all other types is none" do
      [[], list()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == nonempty_charlist() <~> target
      end)
    end
  end
end
