defmodule TypeTest.BuiltinNoReturn.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule NoReturn do
    @type no_return_type :: no_return()
  end)

  describe "the no_return/0 type" do
    test "is itself" do
      assert no_return() == @no_return_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :none, params: []} == @no_return_type
    end
  end
end
