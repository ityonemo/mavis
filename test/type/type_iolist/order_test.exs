defmodule TypeTest.TypeIolist.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.List

  @any builtin(:any)
  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}
  @type @char <|> @binary <|> builtin(:iolist)
  @final [] <|> @binary

  # note that the iolist is nonempty false list
  describe "an iolist" do
    test "is bigger than bottom and reference" do
      assert builtin(:iolist) >
    end

    test "is bigger than `less than complete` iolists" do
      assert builtin(:iolist) > %List{type: builtin(:iolist) <|> @char}
      assert builtin(:iolist) > %List{type: builtin(:iolist) <|> @binary}
      assert builtin(:iolist) > %List{type: @char <|> @binary}
      assert builtin(:iolist) > %List{type: @type}
      assert builtin(:iolist) > %List{type: @type, final: @binary}
    end

    test "is smaller than `strange iolists` which are superclasses" do
      assert builtin(:iolist) < %List{type: @type <|> nil, final: @final}
      assert builtin(:iolist) < %List{type: @type, final: @final <|> nil}
    end

    test "is smaller than arbitrary lists, bitstrings or top" do
      assert builtin(:iolist) < %List{type: @any}
      assert builtin(:iolist) < %Type.Bitstring{size: 0, unit: 0}
      assert builtin(:iolist) < @any
    end
  end

end
