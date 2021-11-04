defmodule TypeTest.BuiltinFun.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the fun type" do
    pull_types(defmodule Fun do
      @type fun_type :: fun
    end)

    test "is itself" do
      assert fun() == @fun_type
    end

    test "matches to itself" do
      assert fun() = @fun_type
    end

    test "is what we expect" do
      assert %Type.Function{params: :any, return: %Type{module: nil, name: :any, params: []}} == @fun_type
    end
  end
end
