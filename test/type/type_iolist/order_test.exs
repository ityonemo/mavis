defmodule TypeTest.TypeIolist.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.{Bitstring, List}

  @any builtin(:any)
  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}
  @ltype @char <|> @binary <|> builtin(:iolist)
  @final [] <|> @binary

  # note that the iolist is nonempty false list
  describe "an iolist" do
    test "is bigger than bottom and reference" do
      assert builtin(:iolist) > builtin(:none)
      assert builtin(:iolist) > builtin(:reference)
    end

    test "is bigger than `less than complete` iolists" do
      assert builtin(:iolist) > list(builtin(:iolist) <|> @char)
      assert builtin(:iolist) > list(builtin(:iolist) <|> @binary)
      assert builtin(:iolist) > list(@char <|> @binary)
      assert builtin(:iolist) > list(@ltype)
      assert builtin(:iolist) > %List{type: @ltype, nonempty: true, final: @binary}
    end

    test "is equal to manually defined iolists with recursion" do
      assert :eq == Type.compare(builtin(:iolist),
        %List{type: @ltype, final: @final})
      assert :eq == Type.compare(builtin(:iolist),
        %List{type: %List{type: @ltype, final: @final} <|> @char <|> @binary,
              final: @final})
    end

    test "is smaller than a union containing it" do
      assert builtin(:iolist) < nil <|> builtin(:iolist)
    end

    test "is smaller than `strange iolists` which are superclasses" do
      assert builtin(:iolist) < %List{type: @ltype <|> nil, final: @final}
      assert builtin(:iolist) < %List{type: @ltype, final: @final <|> nil}
    end

    test "is smaller than arbitrary lists, bitstrings or top" do
      assert builtin(:iolist) < builtin(:list)
      assert builtin(:iolist) < %Type.Bitstring{size: 0, unit: 0}
      assert builtin(:iolist) < @any
    end
  end

end
