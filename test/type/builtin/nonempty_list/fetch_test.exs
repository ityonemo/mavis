defmodule TypeTest.BuiltinNonemptyList.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule NonemptyList do
    @type nonempty_list_type :: nonempty_list()
    @type nonempty_list_with_type :: nonempty_list(:foo)
  end)

  describe "the nonempty_list/0 type" do
    test "is itself" do
      assert nonempty_list() == @nonempty_list_type
    end

    test "is what we expect" do
      assert %Type.List{type: any(), final: []} == @nonempty_list_type
    end
  end

  describe "the nonempty_list/1 type" do
    test "is itself" do
      assert nonempty_list(:foo) == @nonempty_list_with_type
    end

    test "is what we expect" do
      assert %Type.List{type: :foo, final: []} == @nonempty_list_with_type
    end
  end
end
