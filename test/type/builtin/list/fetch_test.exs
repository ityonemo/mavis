defmodule TypeTest.BuiltinList.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the list type" do
    pull_types(defmodule List do
      @type list_type :: list
      @type list_with_type :: list(atom)
    end)

    test "is itself" do
      assert list() == @list_type
      assert list(atom()) == @list_with_type
    end

    test "matches to itself" do
      assert list() = @list_type
      assert list(atom()) = @list_with_type
    end

    test "can match to a variable" do
      assert list(t) = @list_with_type
      assert t == atom()
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{
        type: any(),
        final: []}, []]} == @list_type

      assert %Type.Union{of: [%Type.List{
        type: atom(),
        final: []}, []]} == @list_with_type
    end
  end
end
