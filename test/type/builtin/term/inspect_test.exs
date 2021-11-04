defmodule TypeTest.BuiltinTerm.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the term type" do
    pull_types(defmodule Term do
      @type term_type :: term
    end)

    test "looks like a none" do
      assert "any()" == inspect(@term_type)
    end

    test "code translates correctly" do
      assert @term_type == eval_type_str("term()")
    end
  end
end
