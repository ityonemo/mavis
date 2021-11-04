defmodule TypeTest.BuiltinAtom.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the atom type" do
    pull_types(defmodule Atom do
      @type atom_type :: atom
    end)

    test "is itself" do
      assert atom() == @atom_type
    end

    test "matches to itself" do
      assert atom() = @atom_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :atom, params: []} == @atom_type
    end
  end
end
