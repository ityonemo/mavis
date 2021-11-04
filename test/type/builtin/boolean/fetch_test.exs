defmodule TypeTest.BuiltinBoolean.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the boolean type" do
    pull_types(defmodule Boolean do
      @type boolean_type :: boolean
    end)

    test "is itself" do
      assert boolean() == @boolean_type
    end

    test "matches to itself" do
      assert boolean() = @boolean_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [true, false]} == @boolean_type
    end
  end
end
