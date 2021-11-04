defmodule TypeTest.BuiltinNonemptyImproperList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the nonempty_improper_list type" do
    pull_types(defmodule NonemptyImproperList do
      @type nonempty_improper_list_type :: nonempty_improper_list(:foo, :bar)
    end)

    test "looks like itself" do
      assert "nonempty_improper_list(:foo, :bar)" == inspect(@nonempty_improper_list_type)
    end

    test "code translates correctly" do
      assert @nonempty_improper_list_type == eval_inspect(@nonempty_improper_list_type)
    end
  end
end
