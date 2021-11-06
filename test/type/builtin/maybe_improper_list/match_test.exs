defmodule TypeTest.BuiltinMaybeImproperList.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the maybe_improper_list/0 type" do
    @maybe_improper_list_type %Type.Union{of: [%Type.List{type: any(), final: any()}, []]}
    @maybe_improper_list_with_types

    test "matches with itself" do
      assert maybe_improper_list() = @maybe_improper_list_type
    end
  end

  describe "the maybe_improper_list/2 type" do
    test "can't be used in a match" do
      assert_raise CompileError, fn ->
        Code.compile_string("""
        defmodule MaybeImproperList do
          import Type, only: :macros
          def match?(v) do
            case (v) do
              maybe_improper_list(_, _) -> true
              _ -> false
            end
          end
        end
        """)
      end
    end
  end
end
