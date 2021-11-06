defmodule TypeTest.BuiltinFloat.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Float do
    @type float_type :: float
  end)

  describe "the float/0 type" do
    test "is itself" do
      assert float() == @float_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :float, params: []} == @float_type
    end
  end
end
