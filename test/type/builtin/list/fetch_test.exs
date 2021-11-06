defmodule TypeTest.BuiltinList.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule List do
    @type list_type :: list
    @type list_with_type :: list(atom)
  end)

  describe "the list/0 type" do
    test "is itself" do
      assert list() == @list_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{
        type: any(),
        final: []}, []]} == @list_type
    end
  end

  describe "the list/1 type" do
    test "is itself" do
      assert list(atom()) == @list_with_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{
        type: atom(),
        final: []}, []]} == @list_with_type
    end
  end
end
