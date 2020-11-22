defmodule TypeTest.NormalizationTest do

  # tests on the Type module
  use ExUnit.Case, async: true

  # allows us to use these in doctests
  import Type, only: :macros

  # ensures that types that deviate from the elixir and erlang standard
  # are able to be "renormalized" to the expected types.

  describe "String.t/1" do
    test "is normalized back to String.t" do
      refute remote(String.t()) == remote(String.t(8))
      assert remote(String.t) == Type.normalize(remote(String.t(8)))
    end
  end

  describe "min-arity tuples" do
    test "are normalized to general tuples" do
      refute tuple() == tuple({...(min: 3)})
      assert tuple() == Type.normalize(tuple({...(min: 3)}))
    end
  end

end
