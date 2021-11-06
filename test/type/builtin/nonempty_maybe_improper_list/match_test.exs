defmodule TypeTest.BuiltinNonEmptyMaybeImproperList.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the nonempty_maybe_improper_list/0 type" do
    @nonempty_maybe_improper_list_type %Type.List{type: any(), final: any()}

    test "matches with itself" do
      assert nonempty_maybe_improper_list() = @nonempty_maybe_improper_list_type
    end
  end

  describe "the maybe_improper_list/2 type" do
    test "can't be used in a match" do
      assert_raise CompileError, fn ->
        Code.compile_string("""
        defmodule NonemptyMaybeImproperList do
          import Type, only: :macros
          def match?(v) do
            case (v) do
              nonempty_maybe_improper_list(_, _) -> true
              _ -> false
            end
          end
        end
        """)
      end
    end
  end
end
