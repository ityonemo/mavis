defmodule TypeTest.BuiltinAny.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the any type" do
    pull_types(defmodule Any do
      @type any_type :: any
    end)

    test "is itself" do
      assert any() == @any_type
    end

    test "matches to itself" do
      assert any() = @any_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :any, params: []} == @any_type
    end
  end
end
