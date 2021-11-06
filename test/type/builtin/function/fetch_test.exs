defmodule TypeTest.BuiltinFunction.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Function do
    @type function_type :: function
  end)

  describe "the function/0 type" do
    test "is itself" do
      assert function() == @function_type
    end

    test "is what we expect" do
      assert %Type.Function{params: :any, return: any()}} == @function_type
    end
  end
end
