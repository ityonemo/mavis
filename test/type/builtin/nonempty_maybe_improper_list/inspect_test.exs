defmodule TypeTest.BuiltinNonemptyMaybeImproperList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the nonempty_maybe_improper_list type" do
    pull_types(defmodule NonemptyMaybeImproperList do
      @type nonempty_maybe_improper_list_type :: nonempty_maybe_improper_list()
      @type nonempty_maybe_improper_list_plus :: nonempty_maybe_improper_list() | nil
    end)

    test "is presented as itself" do
      assert "nonempty_maybe_improper_list()" == inspect(@nonempty_maybe_improper_list_type)
    end

    test "code translates correctly" do
      assert @nonempty_maybe_improper_list_type == eval_inspect(@nonempty_maybe_improper_list_type)
    end

    test "works with plus" do
      assert "nil <|> nonempty_maybe_improper_list()" == inspect(@nonempty_maybe_improper_list_plus)
    end
  end
end
