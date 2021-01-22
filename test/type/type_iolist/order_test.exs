defmodule TypeTest.TypeIolist.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.{Bitstring, List}

  @any any()
  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}
  @ltype @char <|> @binary <|> iolist()
  @final [] <|> @binary

  # note that the iolist is nonempty false list
  describe "an iolist" do
    test "is bigger than bottom and reference" do
      assert iolist() > none()
      assert iolist() > reference()
    end

    test "is bigger than `less than complete` iolists" do
      assert iolist() > list(iolist() <|> @char)
      assert iolist() > list(iolist() <|> @binary)
      assert iolist() > list(@char <|> @binary)
      assert iolist() > list(@ltype)
      assert iolist() > %List{type: @ltype, final: @binary}
    end

    test "is equal to manually defined iolists with recursion" do
      assert :eq == Type.compare(iolist(),
        %List{type: @ltype, final: @final})
      assert :eq == Type.compare(iolist(),
        %List{type: %List{type: @ltype, final: @final} <|> @char <|> @binary,
              final: @final})
    end

    test "is smaller than a union containing it" do
      assert iolist() < nil <|> iolist()
    end

    test "is smaller than `strange iolists` which are superclasses" do
      assert iolist() < %List{type: @ltype <|> nil, final: @final}
      assert iolist() < %List{type: @ltype, final: @final <|> nil}
    end

    test "is smaller than arbitrary lists, bitstrings or top" do
      assert iolist() < list()
      assert iolist() < %Type.Bitstring{size: 0, unit: 0}
      assert iolist() < @any
    end
  end

end
