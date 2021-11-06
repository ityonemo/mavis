defmodule TypeTest.BuiltinNumber.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Number do
    @type number_type :: number()
  end)

  describe "the number/0 type" do
    test "is itself" do
      assert number() == @number_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [
        float(),
        pos_integer(),
        0,
        neg_integer()
      ]} == @number_type
    end
  end
end
