defmodule TypeTest.BuiltinReference.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Reference do
    @type reference_type :: reference()
  end)

  describe "the reference/0 type" do
    test "is itself" do
      assert reference() == @reference_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :reference, params: []} == @reference_type
    end
  end
end
