defmodule TypeTest.TypeIolist.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  alias Type.{Bitstring, List}

  use Type.Operators

  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}
  @ltype @char <|> @binary <|> builtin(:iolist)
  @final [] <|> @binary

  describe "the iolist" do
    test "is a subtype of itself, general maybe improper list, and any" do
      assert builtin(:iolist) in builtin(:iolist)
      assert builtin(:iolist) in %List{final: builtin(:any)}
      assert builtin(:iolist) in builtin(:any)
    end

    test "is a subtype of itself defined recursively" do
      assert builtin(:iolist) in %List{type: @ltype, final: @final}
      assert builtin(:iolist) in
        %List{type: %List{type: @ltype, final: @final} <|> @char <|> @binary,
              final: @final}
    end

    test "is not a subtype of a list missing iolist, binary, or char are subtypes of iolists" do
      refute builtin(:iolist) in %List{type: @char <|> builtin(:iolist), final: @final}
      refute builtin(:iolist) in %List{type: @binary <|> builtin(:iolist), final: @final}
      refute builtin(:iolist) in %List{type: @char <|> @binary, final: @final}
    end

    test "is not a subtype of a list missing a final component are subtypes of iolists" do
      refute builtin(:iolist) in %List{type: @ltype}
      refute builtin(:iolist) in %List{type: @ltype, final: @binary}
    end

    test "is not a subtype of a list that are nonempty: true are subtypes of iolists" do
      refute builtin(:iolist) in %List{type: @ltype, final: @final, nonempty: true}
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([%List{}])
      |> Enum.each(fn target ->
        refute builtin(:iolist) in target
      end)
    end
  end

  describe "lists" do
    test "missing iolist, binary, or char are subtypes of iolists" do
      assert %List{type: @char <|> builtin(:iolist), final: @final} in builtin(:iolist)
      assert %List{type: @binary <|> builtin(:iolist), final: @final} in builtin(:iolist)
      assert %List{type: @char <|> @binary, final: @final} in builtin(:iolist)
    end

    test "missing a final component are subtypes of iolists" do
      assert %List{type: @ltype} in builtin(:iolist)
      assert %List{type: @ltype, final: @binary} in builtin(:iolist)
    end

    test "that are nonempty: true are subtypes of iolists" do
      assert %List{type: @ltype, final: @final, nonempty: true} in builtin(:iolist)
    end
  end
end
