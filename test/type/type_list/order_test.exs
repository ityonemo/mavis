defmodule TypeTest.TypeList.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.List

  describe "a nonempty true list" do
    test "is bigger than bottom and reference" do
      assert list(...) > builtin(:none)
      assert list(...) > builtin(:reference)
    end

    test "is bigger than a list which is a subclass" do
      assert list(...) > list(builtin(:integer), ...)
      # because the final is more general
      assert %List{type: builtin(:any), final: builtin(:any)} >
        list(builtin(:any), ...)
    end

    test "is smaller than a list which is a superclass" do
      assert list(builtin(:integer), ...) < list(...)
      assert list(builtin(:integer), ...) < list(builtin(:integer))
      # because the final is more general
      assert list(...) < %List{type: builtin(:any), final: builtin(:any)}
    end

    test "is smaller than maybe-empty lists, empty list, bitstrings or top" do
      assert list(...) < []
      assert list(...) < list(builtin(:integer))
      assert list(...) < %Type.Bitstring{size: 0, unit: 0}
      assert list(...) < builtin(:any)
    end
  end

  describe "a nonempty false list" do
    test "is bigger than bottom and reference, and empty list" do
      assert builtin(:list) > builtin(:none)
      assert builtin(:list) > builtin(:reference)
      assert builtin(:list) > []
    end

    test "is bigger than a list which is nonempty: true" do
      assert list(builtin(:integer)) > list(builtin(:any), ...)
    end

    test "is bigger than a list which is a subclass" do
      assert builtin(:list) > list(builtin(:integer))
      # because the final is more general
      assert %List{type: builtin(:any), final: builtin(:any)} > builtin(:list)
    end

    test "is smaller than a union containing it" do
      assert builtin(:list) < (nil <|> builtin(:list))
    end

    test "is smaller than a list which is a superclass" do
      assert list(builtin(:integer)) < builtin(:list)
      # because the final is more general
      assert builtin(:list) < %List{type: builtin(:any), final: builtin(:any)}
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert builtin(:list) < %Type.Bitstring{size: 0, unit: 0}
      assert builtin(:list) < builtin(:any)
    end
  end

end
