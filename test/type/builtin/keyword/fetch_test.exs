defmodule TypeTest.BuiltinKeyword.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Keyword do
    @type keyword_type :: keyword
    @type keyword_with_type :: keyword(atom)
  end)

  describe "the keyword/0 type" do
    test "is itself" do
      assert keyword() == @keyword_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{
        type: %Type.Tuple{
          elements: [atom(), any()],
          fixed: true
        },
        final: []}, []]} == @keyword_type
    end
  end

  describe "the keyword/1 type" do
    test "is itself" do
      assert keyword(atom()) == @keyword_with_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{
        type: %Type.Tuple{
          elements: [atom(), atom()],
          fixed: true
        },
        final: []}, []]} == @keyword_with_type
    end
  end
end
