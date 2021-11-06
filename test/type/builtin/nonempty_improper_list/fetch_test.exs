defmodule TypeTest.BuiltinNonemptyImproperList.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule NonemptyImproperList do
    @type nonempty_improper_list_type :: nonempty_improper_list(:foo, :bar)
  end)

  describe "the nonempty_improper_list/0 type" do
    test "is itself" do
      assert nonempty_improper_list(:foo, :bar) == @nonempty_improper_list_type
    end

    test "is what we expect" do
      assert %Type.List{type: :foo, final: :bar} == @nonempty_improper_list_type
    end
  end
end
