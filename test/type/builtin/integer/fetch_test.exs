defmodule TypeTest.BuiltinInteger.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Integer do
    @type integer_type :: integer
  end)

  describe "the integer/0 type" do
    test "is itself" do
      assert integer() == @integer_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [pos_integer(), 0, neg_integer()]} == @integer_type
    end
  end
end
