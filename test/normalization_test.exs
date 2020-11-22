defmodule TypeTest.NormalizationTest do

  # tests on the Type module
  use ExUnit.Case, async: true

  # allows us to use these in doctests
  import Type, only: :macros

  # ensures that types that deviate from the elixir and erlang standard
  # are able to be "renormalized" to the expected types.

  describe "all mainline types" do
    test "do not get changed by normalization" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert target == Type.normalize(target)
      end)
    end
  end


  describe "String.t/1" do
    test "is normalized back to String.t" do
      refute remote(String.t()) == remote(String.t(8))
      assert remote(String.t) == Type.normalize(remote(String.t(8)))
    end
  end

  describe "min-arity tuples" do
    test "are normalized to general tuples" do
      refute tuple() == tuple({any(), any(), any(), ...})
      assert tuple() == Type.normalize(tuple({any(), any(), any(), ...}))
    end
  end

  describe "top-arity functions" do
    test "are normalized to any... functions" do
      refute function((any() -> any())) == function((_ -> any()))
      assert function((any() -> any())) == Type.normalize(function((_ -> any())))

      # with a non-"any" return type
      refute function((any() -> :foo)) ==
        function((_ -> :foo))
      assert function((any() -> :foo)) ==
        Type.normalize(function((_ -> :foo)))

      # with more than 1 arity
      refute function((any(), any() -> any())) ==
        function((_, _ -> any()))
      assert function((any(), any() -> any())) ==
        Type.normalize(function((_, _ -> any())))
    end
  end

end
