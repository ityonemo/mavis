defmodule TypeTest.BuiltinNonemptyMaybeImproperList.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule NonemptyMaybeImproperList do
    @type nonempty_maybe_improper_list_type :: nonempty_maybe_improper_list()
    @type nonempty_maybe_improper_list_with_type :: nonempty_maybe_improper_list(:foo, :bar)
  end)

  describe "the nonempty_maybe_improper_list/0 type" do
    test "is itself" do
      assert nonempty_maybe_improper_list() == @nonempty_maybe_improper_list_type
    end

    test "is what we expect" do
      assert %Type.List{type: any(), final: any()} == @nonempty_maybe_improper_list_type
    end
  end

  describe "the nonempty_maybe_improper_list/2 type" do
    test "is itself" do
      assert nonempty_maybe_improper_list(:foo, :bar) == @nonempty_maybe_improper_list_with_type
    end

    test "is what we expect" do
      assert %Type.List{type: :foo, final: %Type.Union{of: [[], :bar]}} == @nonempty_maybe_improper_list_with_type
    end
  end
end
