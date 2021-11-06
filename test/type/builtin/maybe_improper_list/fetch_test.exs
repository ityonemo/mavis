defmodule TypeTest.BuiltinMaybeImproperList.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the maybe_improper_list type" do
    pull_types(defmodule MaybeImproperList do
      @type maybe_improper_list_type :: maybe_improper_list
      @type maybe_improper_list_with_types :: maybe_improper_list(atom, float)
    end)

    test "is itself" do
      assert maybe_improper_list() == @maybe_improper_list_type
      assert maybe_improper_list(atom(), float()) == @maybe_improper_list_with_types
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{
        type: any(),
        final: any()}, []]} == @maybe_improper_list_type

      assert %Type.Union{of:
        [%Type.List{
          type: atom(),
          final: %Type.Union{of: [[], float()]}},
        []]} == @maybe_improper_list_with_types
    end
  end
end
