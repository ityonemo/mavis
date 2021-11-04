defmodule TypeTest.BuiltinKeyword.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the keyword type" do
    pull_types(defmodule Keyword do
      @type keyword_type :: keyword
      @type keyword_with_type :: keyword(atom)
    end)

    test "is itself" do
      assert keyword() == @keyword_type
      assert keyword(atom()) == @keyword_with_type
    end

    test "matches to itself" do
      assert keyword() = @keyword_type
      assert keyword(atom()) = @keyword_with_type
    end

    test "can match to a variable" do
      assert keyword(t) = @keyword_with_type
      assert t == atom()
    end

    test "is what we expect" do
      assert %Type.Union{of: [%Type.List{
        type: %Type.Tuple{
          elements: [
            %Type{module: nil, name: :atom, params: []},
            %Type{module: nil, name: :any, params: []}
          ],
          fixed: true
        },
        final: []}, []]} == @keyword_type

      assert %Type.Union{of: [%Type.List{
        type: %Type.Tuple{
          elements: [
            %Type{module: nil, name: :atom, params: []},
            %Type{module: nil, name: :atom, params: []}
          ],
          fixed: true
        },
        final: []}, []]} == @keyword_with_type
    end
  end
end
