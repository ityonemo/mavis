defmodule TypeTest.BuiltinKeyword.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the keyword/0 type" do
    @list_type %Type.Union{of: [
      %Type.List{
        type: %Type.Tuple{elements: [atom(), any()], fixed: true},
        final: []
      },
      []]}

    test "matches with itself" do
      assert keyword() = @list_type
    end
  end

  describe "the keyword/1 type" do
    @list_type %Type.Union{of: [
      %Type.List{
        type: %Type.Tuple{elements: [atom(), atom()], fixed: true},
        final: []
      },
      []]}

    test "matches with itself" do
      assert keyword(atom()) = @list_type
    end

    test "can be used to assign variables" do
      assert keyword(a) = @list_type
      assert a == atom()
    end
  end
end
