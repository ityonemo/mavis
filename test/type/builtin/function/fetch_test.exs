defmodule TypeTest.BuiltinFunction.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the function type" do
    pull_types(defmodule Function do
      @type function_type :: function
    end)

    test "is itself" do
      assert function() == @function_type
    end

    test "matches to itself" do
      assert function() = @function_type
    end

    test "is what we expect" do
      assert %Type.Function{params: :any, return: %Type{module: nil, name: :any, params: []}} == @function_type
    end
  end
end
