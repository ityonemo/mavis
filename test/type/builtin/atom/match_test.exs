defmodule TypeTest.BuiltinAtom.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the atom/0 type" do
    @atom_type %Type{module: nil, name: :atom, params: []}

    test "matches with itself" do
      assert atom() = @atom_type
    end
  end
end
