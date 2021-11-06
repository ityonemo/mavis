defmodule TypeTest.BuiltinNonNegInteger.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule NonNegInteger do
    @type non_neg_integer_type :: non_neg_integer()
  end)

  describe "the non_neg_integer/0 type" do
    test "is itself" do
      assert non_neg_integer() == @non_neg_integer_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [pos_integer(), 0]} == @non_neg_integer_type
    end
  end
end
