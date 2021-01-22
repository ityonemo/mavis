defmodule TypeTest.TypeIolist.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  alias Type.{Bitstring, List}

  use Type.Operators

  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}
  @ltype @char <|> @binary <|> iolist()
  @final [] <|> @binary

  describe "the iolist" do
    test "is a subtype of itself, general maybe improper list, and any" do
      assert iolist() in iolist()
      assert iolist() in %List{final: any()}
      assert iolist() in any()
    end

    test "is a subtype of itself defined recursively" do
      assert iolist() in %List{type: @ltype, final: @final}
      assert iolist() in
        %List{type: %List{type: @ltype, final: @final} <|> @char <|> @binary,
              final: @final}
    end

    test "is a subtype of itself defined explicitly, but with extras" do
      assert iolist() in %List{type: @ltype <|> atom(), final: @final}
      assert iolist() in %List{type: @ltype, final: @final <|> atom()}
    end

    test "is not a subtype of a list missing iolist, binary, or char are subtypes of iolists" do
      refute iolist() in %List{type: @char <|> iolist(), final: @final}
      refute iolist() in %List{type: @binary <|> iolist(), final: @final}
      refute iolist() in %List{type: @char <|> @binary, final: @final}
    end

    test "is not a subtype of a list missing a final component are subtypes of iolists" do
      refute iolist() in list(@ltype)
      refute iolist() in %List{type: @ltype, final: @binary}
    end

    test "is not a subtype of a list that are nonempty: true are subtypes of iolists" do
      refute iolist() in %List{type: @ltype, final: @final}
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([list()])
      |> Enum.each(fn target ->
        refute iolist() in target
      end)
    end
  end

  describe "lists" do
    test "missing iolist, binary, or char are subtypes of iolists" do
      assert %List{type: @char <|> iolist(), final: @final} in iolist()
      assert %List{type: @binary <|> iolist(), final: @final} in iolist()
      assert %List{type: @char <|> @binary, final: @final} in iolist()
    end

    test "missing a final component are subtypes of iolists" do
      assert list(@ltype) in iolist()
      assert %List{type: @ltype, final: @binary} in iolist()
    end

    test "that are nonempty: true are subtypes of iolists" do
      assert %List{type: @ltype, final: @final} in iolist()
    end
  end
end
