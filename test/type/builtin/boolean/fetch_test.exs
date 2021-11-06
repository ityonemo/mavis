defmodule TypeTest.BuiltinBoolean.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Boolean do
    @type boolean_type :: boolean
  end)

  describe "the boolean/0 type" do
    test "is itself" do
      assert boolean() == @boolean_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [true, false]} == @boolean_type
    end
  end
end
