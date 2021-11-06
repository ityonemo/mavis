defmodule TypeTest.BuiltinNonEmptyList.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the nonempty_list/0 type" do
    @nonempty_list_type %Type.List{type: any(), final: []}

    test "matches with itself" do
      assert nonempty_list() = @nonempty_list_type
    end
  end

  describe "the nonempty_list/1 type" do
    @nonempty_list_type %Type.List{type: atom(), final: []}

    test "matches with itself" do
      assert nonempty_list(atom()) = @nonempty_list_type
    end

    test "can be used to assign variables" do
      assert nonempty_list(a) = @nonempty_list_type
      assert a == atom()
    end
  end
end
