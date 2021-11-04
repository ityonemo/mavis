defmodule TypeTest.BuiltinAtom.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the atom type" do
    pull_types(defmodule Atom do
      @type atom_type :: atom
    end)

    test "looks like an atom" do
      assert "atom()" == inspect(@atom_type)
    end

    test "code translates correctly" do
      assert @atom_type == eval_inspect(@atom_type)
    end
  end
end
