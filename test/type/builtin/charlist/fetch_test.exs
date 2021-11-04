defmodule TypeTest.BuiltinCharlist.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the charlist type" do
    pull_types(defmodule Charlist do
      @type charlist_type :: charlist
    end)

    test "is itself" do
      assert charlist() == @charlist_type
    end

    test "matches to itself" do
      assert charlist() = @charlist_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{type: 0..0x10_FFFF, final: []}, []]} == @charlist_type
    end
  end
end
