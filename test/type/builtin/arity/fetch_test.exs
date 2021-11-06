defmodule TypeTest.BuiltinArity.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Arity do
    @type arity_type :: arity
  end)

  describe "the arity/0 type" do
    test "is itself" do
      assert arity() == @arity_type
    end

    test "is what we expect" do
      assert 0..255 == @arity_type
    end
  end
end
