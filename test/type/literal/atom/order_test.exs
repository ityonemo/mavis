defmodule TypeTest.LiteralAtom.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  describe "an atom literal" do
    test "is bigger than bottom and integers" do
      assert :foo > none()
      assert :foo > integer()
    end

    test "has the expected erlang relations" do
      assert :foo > :bar
      assert :bar < :foo
    end

    test "is smaller than a union containing it" do
      assert :foo < :foo <|> :bar
    end

    test "is smaller than atom, which it is a subset of" do
      assert :foo < atom()
    end

    test "is smaller than reference and top" do
      assert :foo < reference()
      assert :foo < any()
    end
  end

end
