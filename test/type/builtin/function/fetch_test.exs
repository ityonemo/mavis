defmodule TypeTest.BuiltinFunction.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch
  @moduletag :function

  pull_types(defmodule Function do
    @type function_type :: function
  end)

  describe "the function/0 type" do
    test "is itself" do
      assert function() == @function_type
    end

    test "is what we expect" do
      assert %Type.Function{branches: [%Type.Function.Branch{params: :any, return: any()}]} == @function_type
    end
  end
end
