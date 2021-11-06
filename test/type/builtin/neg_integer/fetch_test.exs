defmodule TypeTest.BuiltinNegInteger.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule NegInteger do
    @type neg_integer_type :: neg_integer()
  end)

  describe "the neg_integer/0 type" do
    test "is itself" do
      assert neg_integer() == @neg_integer_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :neg_integer, params: []} == @neg_integer_type
    end
  end
end
