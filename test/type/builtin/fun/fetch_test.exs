defmodule TypeTest.BuiltinFun.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch
  @moduletag :function

  pull_types(defmodule Fun do
    @type fun_type :: fun
  end)

  describe "the fun/0 type" do
    test "is itself" do
      assert fun() == @fun_type
    end

    test "is what we expect" do
      assert %Type.Function{branches: [%Type.Function.Branch{params: :any, return: any()}]} == @fun_type
    end
  end
end
