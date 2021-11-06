defmodule TypeTest.BuiltinTerm.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Term do
    @type term_type :: term()
  end)

  describe "the term/0 type" do
    test "is itself" do
      assert term() == @term_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :any, params: []} == @term_type
    end
  end
end
