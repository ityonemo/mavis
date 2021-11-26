defmodule TypeTest.TypeIolist.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators
  alias Type.List
  alias Type.Union

  @ltype byte() <|> binary() <|> iolist()
  @final [] <|> binary()

  # note that the iolist is nonempty false list
  describe "an iolist" do
    test "is bigger than bottom and reference" do
      assert iolist() > none()
      assert iolist() > reference()
    end

    test "is bigger than `less than complete` iolists" do
      assert iolist() > list(iolist() <|> byte())
      assert iolist() > list(iolist() <|> binary())
      assert iolist() > list(byte() <|> binary())
      assert iolist() > list(@ltype)
      assert iolist() > %List{type: @ltype, final: binary()}
    end

    test "is equal to manually defined iolists with recursion" do
      iolist_t = %Type.Union{of: [%List{type: @ltype, final: @final}, []]}
      iolist2_t = %Type.Union{
        of: [%List{
          type: %Type.Union{of: [binary(), iolist(), byte()]},
          final: @final},
        []]
      }

      assert :eq == Type.compare(iolist(), iolist_t)
      assert :eq == Type.compare(iolist_t, iolist2_t)
      assert :eq == Type.compare(iolist(), iolist2_t)
    end

    test "is smaller than a union containing it" do
      assert iolist() < %Union{of: [iolist(), nil]}
    end

    test "is smaller than `strange iolists` which are superclasses" do
      assert iolist() < %List{type: @ltype <|> nil, final: @final}
      assert iolist() < %List{type: @ltype, final: @final <|> nil}
    end

    test "is smaller than arbitrary lists, bitstrings or top" do
      assert iolist() < list()
      assert iolist() < %Type.Bitstring{size: 0, unit: 0}
      assert iolist() < any()
    end
  end

end
