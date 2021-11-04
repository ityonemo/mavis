defmodule TypeTest.LiteralAtom.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the literal atom type" do
    pull_types(defmodule LiteralAtom do
      @type literal_atom :: :literal
    end)

    test "looks like an atom" do
      assert ":literal" == inspect(@literal_atom)
    end

    test "code translates correctly" do
      assert @literal_atom == eval_inspect(@literal_atom)
    end
  end
end
