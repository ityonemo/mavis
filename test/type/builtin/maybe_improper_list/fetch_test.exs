defmodule TypeTest.BuiltinMaybeImproperList.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule MaybeImproperList do
    @type maybe_improper_list_type :: maybe_improper_list
    @type maybe_improper_list_with_types :: maybe_improper_list(atom, float)
  end)

  describe "the maybe_improper_list/0 type" do
    test "is itself" do
      assert maybe_improper_list() == @maybe_improper_list_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{
        type: any(),
        final: any()}, []]} == @maybe_improper_list_type
    end
  end

  describe "the maybe_improper_list/2 type" do
    test "is itself" do
      assert maybe_improper_list(atom(), float()) == @maybe_improper_list_with_types
    end

    test "is what we expect" do
      assert %Type.Union{of:
        [%Type.List{
          type: atom(),
          final: %Type.Union{of: [[], float()]}},
        []]} == @maybe_improper_list_with_types
    end
  end
end
