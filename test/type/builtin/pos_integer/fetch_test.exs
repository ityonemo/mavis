defmodule TypeTest.BuiltinPosInteger.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule PosInteger do
    @type pos_integer_type :: pos_integer()
  end)

  describe "the pos_integer/0 type" do
    test "is itself" do
      assert pos_integer() == @pos_integer_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :pos_integer, params: []} == @pos_integer_type
    end
  end
end
