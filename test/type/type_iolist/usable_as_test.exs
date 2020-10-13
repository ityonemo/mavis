defmodule TypeTest.TypeIoist.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]
  use Type.Operators

  alias Type.{Bitstring, List, Message}

  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}
  @ltype @char <|> @binary <|> builtin(:iolist)
  @final [] <|> @binary

  describe "the iolist" do
    test "is usable as itself, general maybe improper list, and any" do
      assert :ok == builtin(:iolist) ~> builtin(:iolist)
      assert :ok == builtin(:iolist) ~> %List{final: builtin(:any)}
      assert :ok == builtin(:iolist) ~> builtin(:any)
    end

    test "is usable as itself defined recursively" do
      assert :ok == builtin(:iolist) ~> %List{type: @ltype, final: @final}
      assert :ok == builtin(:iolist) ~>
        %List{type: %List{type: @ltype, final: @final} <|> @char <|> @binary,
              final: @final}
    end

    test "is maybe usable as a list missing iolist, binary, or char are subtypes of iolists" do
      assert {:maybe, _} = builtin(:iolist) ~> %List{type: @char <|> builtin(:iolist), final: @final}
      assert {:maybe, _} = builtin(:iolist) ~> %List{type: @binary <|> builtin(:iolist), final: @final}
      assert {:maybe, _} = builtin(:iolist) ~> %List{type: @char <|> @binary, final: @final}
    end

    test "is maybe usable as a list missing a final component are subtypes of iolists" do
      assert {:maybe, _} = builtin(:iolist) ~> %List{type: @ltype}
      assert {:maybe, _} = builtin(:iolist) ~> %List{type: @ltype, final: @binary}
    end

    test "is maybe usable as a list that are nonempty: true are subtypes of iolists" do
      assert {:maybe, _} = builtin(:iolist) ~> %List{type: @ltype, final: @final, nonempty: true}
    end

    test "is not usable as a list with totally different types" do
      assert {:error, _} = builtin(:iolist) ~> %List{type: builtin(:atom)}
    end

    test "are not usable as other types" do
      TypeTest.Targets.except([%List{}])
      |> Enum.each(fn target ->
        assert {:error, _} = builtin(:iolist) ~> target
      end)
    end
  end

  describe "lists" do
    test "missing iolist, binary, or char are usable as iolists" do
      assert :ok = %List{type: @char <|> builtin(:iolist), final: @final} ~> builtin(:iolist)
      assert :ok = %List{type: @binary <|> builtin(:iolist), final: @final} ~> builtin(:iolist)
      assert :ok = %List{type: @char <|> @binary, final: @final} ~> builtin(:iolist)
    end

    test "missing a final component are usable as iolists" do
      assert :ok = %List{type: @ltype} in builtin(:iolist)
      assert :ok = %List{type: @ltype, final: @binary} ~> builtin(:iolist)
    end

    test "that are nonempty: true are usable as iolists" do
      assert :ok = %List{type: @ltype, final: @final, nonempty: true} ~> builtin(:iolist)
    end

    test "overly large domains are maybe usable" do
      assert {:maybe, _} = %List{type: builtin(:any)} ~> builtin(:iolist)
      assert {:maybe, _} = %List{type: @ltype, final: builtin(:any)} ~> builtin(:iolist)
    end

    test "with nothing in common are not usable as iolists" do
      assert {:error, _} = %List{type: builtin(:atom)} ~> builtin(:iolist)
      assert {:error, _} = %List{type: builtin(:any), final: builtin(:atom)} ~>
        builtin(:iolist)
    end
  end
end
