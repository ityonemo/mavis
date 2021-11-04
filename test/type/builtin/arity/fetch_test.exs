defmodule TypeTest.BuiltinArity.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the arity type" do
    pull_types(defmodule Any do
      @type arity_type :: arity
    end)

    test "is itself" do
      assert arity() == @arity_type
    end

    test "matches to itself" do
      assert arity() = @arity_type
    end

    test "is what we expect" do
      assert 0..255 == @arity_type
    end
  end
end
