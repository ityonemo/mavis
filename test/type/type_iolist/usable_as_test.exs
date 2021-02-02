defmodule TypeTest.TypeIoist.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros
  use Type.Operators

  alias Type.{Bitstring, NonemptyList}

  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}
  @ltype @char <|> @binary <|> iolist()
  @final [] <|> @binary

  describe "the iolist" do
    test "is usable as itself, general maybe improper list, and any" do
      assert :ok == iolist() ~> iolist()
      assert :ok == iolist() ~> maybe_improper_list()
      assert :ok == iolist() ~> any()
    end

    @explicit_iolist %Type.NonemptyList{
      final: binary() <|> [],
      type: binary() <|> char() <|> iolist()
    } <|> []

    test "is usable as itself defined recursively" do
      assert :ok == iolist() ~> %NonemptyList{type: @ltype, final: @final}
      assert :ok == iolist() ~>
        %NonemptyList{type: %NonemptyList{type: @ltype, final: @final} <|> @char <|> @binary,
              final: @final}
    end

    test "is maybe usable as a list missing iolist, binary, or char are subtypes of iolists" do
      assert {:maybe, _} = iolist() ~> %NonemptyList{type: @char <|> iolist(), final: @final}
      assert {:maybe, _} = iolist() ~> %NonemptyList{type: @binary <|> iolist(), final: @final}
      assert {:maybe, _} = iolist() ~> %NonemptyList{type: @char <|> @binary, final: @final}
    end

    test "is maybe usable as a list missing a final component are subtypes of iolists" do
      assert {:maybe, _} = iolist() ~> list(@ltype)
      assert {:maybe, _} = iolist() ~> %NonemptyList{type: @ltype, final: @binary}
    end

    test "is maybe usable as a list that are nonempty: true are subtypes of iolists" do
      assert {:maybe, _} = iolist() ~> %NonemptyList{type: @ltype, final: @final}
    end

    test "is maybe usable as an empty list" do
      assert {:maybe, _} = iolist() ~> []
    end

    test "is maybe usable as a list with totally different types" do
      assert {:maybe, _} = iolist() ~> list(atom())
    end

    test "is not usable as a nonempty list with totally different types, or final" do
      assert {:error, _} = iolist() ~> list(atom(), ...)
      assert {:error, _} = iolist() ~> %NonemptyList{type: atom(), final: atom()}
    end

    test "are not usable as other types" do
      TypeTest.Targets.except([[], list()])
      |> Enum.each(fn target ->
        assert {:error, _} = iolist() ~> target
      end)
    end
  end

  describe "lists" do
    test "empty list is usable as iolist" do
      assert :ok = [] ~> iolist()
    end

    test "missing iolist, binary, or char are usable as iolists" do
      assert :ok = %NonemptyList{type: @char <|> iolist(), final: @final} ~> iolist()
      assert :ok = %NonemptyList{type: @binary <|> iolist(), final: @final} ~> iolist()
      assert :ok = %NonemptyList{type: @char <|> @binary, final: @final} ~> iolist()
    end

    test "missing a final component are usable as iolists" do
      assert :ok = list(@ltype) ~> iolist()
      assert :ok = %NonemptyList{type: @ltype, final: @binary} ~> iolist()
    end

    test "that are nonempty: true are usable as iolists" do
      assert :ok = %NonemptyList{type: @ltype, final: @final} ~> iolist()
    end

    test "overly large domains are maybe usable" do
      assert {:maybe, _} = list(any()) ~> iolist()
      assert {:maybe, _} = %NonemptyList{type: @ltype, final: any()} ~> iolist()
    end

    test "any is maybe usable" do
      assert {:maybe, _} = any() ~> iolist()
    end

    test "with nothing in common are maybe usable as iolists" do
      assert {:maybe, _} = list(atom()) ~> iolist()
    end

    test "with either incompatible final terms or nonempty are not usable as iolists" do
      assert {:error, _} = list(atom(), ...) ~> iolist()
      assert {:error, _} = %NonemptyList{type: any(), final: atom()} ~>
        iolist()
    end
  end
end
