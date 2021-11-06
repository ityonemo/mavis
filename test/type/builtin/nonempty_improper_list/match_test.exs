defmodule TypeTest.BuiltinNonEmptyImproperList.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the nonempty_improper_list/2 type" do
    @nonempty_improper_list_type %Type.List{type: :foo, final: :bar}

    test "matches with itself" do
      assert nonempty_improper_list(:foo, :bar) = @nonempty_improper_list_type
    end

    test "can be used to assign variables" do
      assert nonempty_improper_list(a, b) = @nonempty_improper_list_type
      assert a == :foo
      assert b == :bar
    end
  end
end
