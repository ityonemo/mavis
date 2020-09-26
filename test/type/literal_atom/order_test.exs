defmodule TypeTest.LiteralAtom.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "an atom literal" do
    test "is bigger than bottom and integers" do
      assert :foo > builtin(:none)
      assert :foo > builtin(:integer)
    end

    test "has the expected erlang relations" do
      assert :foo > :bar
      assert :bar < :foo
    end

    test "is smaller than atom, which it is a subset of" do
      assert :foo < builtin(:atom)
    end

    test "is smaller than reference and top" do
      assert :foo < builtin(:reference)
      assert :foo < builtin(:any)
    end
  end

end
