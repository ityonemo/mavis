defmodule TypeTest.TypeIolist.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  alias Type.{Bitstring, NonemptyList}

  use Type.Operators

  @ltype byte() <|> binary() <|> iolist()
  @final [] <|> binary()

  describe "the iolist" do
    test "is a subtype of itself, general maybe improper list, and any" do
      assert iolist() in iolist()
      assert iolist() in maybe_improper_list()
      assert iolist() in any()
    end

    test "is a subtype of itself defined recursively" do
      assert iolist() in explicit_iolist()
    end

    test "is a subtype of itself defined explicitly, but with extras" do
      assert iolist() in maybe_improper_list(@ltype <|> atom(), @final)
      assert iolist() in maybe_improper_list(@ltype, @final <|> atom())
    end

    test "is not a subtype of a list missing iolist, binary, or char are subtypes of iolists" do
      refute iolist() in %NonemptyList{type: byte() <|> iolist(), final: @final}
      refute iolist() in %NonemptyList{type: binary() <|> iolist(), final: @final}
      refute iolist() in %NonemptyList{type: byte() <|> binary(), final: @final}
    end

    test "is not a subtype of a list missing a final component are subtypes of iolists" do
      refute iolist() in list(@ltype)
      refute iolist() in %NonemptyList{type: @ltype, final: binary()}
    end

    test "is not a subtype of a list that are nonempty: true are subtypes of iolists" do
      refute iolist() in %NonemptyList{type: @ltype, final: @final}
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
      assert %NonemptyList{type: byte() <|> iolist(), final: @final} in iolist()
      assert %NonemptyList{type: binary() <|> iolist(), final: @final} in iolist()
      assert %NonemptyList{type: byte() <|> binary(), final: @final} in iolist()
    end

    test "missing a final component are subtypes of iolists" do
      assert list(@ltype) in iolist()
      assert %NonemptyList{type: @ltype, final: binary()} in iolist()
    end

    test "that are nonempty: true are subtypes of iolists" do
      assert %NonemptyList{type: @ltype, final: @final} in iolist()
    end
  end
end
