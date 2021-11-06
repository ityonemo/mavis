defmodule TypeTest.BuiltinList.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the list/0 type" do
    @list_type %Type.Union{of: [%Type.List{type: any(), final: []}, []]}

    test "matches with itself" do
      assert list() = @list_type
    end
  end

  describe "the list/1 type" do
    @list_type %Type.Union{of: [%Type.List{type: atom(), final: []}, []]}

    test "matches with itself" do
      assert list(atom()) = @list_type
    end

    test "can be used to assign variables" do
      assert list(a) = @list_type
      assert a == atom()
    end
  end
end
