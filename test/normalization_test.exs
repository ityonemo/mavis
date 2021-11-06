#defmodule TypeTest.NormalizationTest do
#
#  # tests on the Type module
#  use ExUnit.Case, async: true
#
#  # allows us to use these in doctests
#  import Type, only: :macros
#
#  # ensures that types that deviate from the elixir and erlang standard
#  # are able to be "renormalized" to the expected types.
#
#  describe "all mainline types" do
#    test "do not get changed by normalization" do
#      TypeTest.Targets.except([47.0, "foo", <<0::7>>, ["foo", "bar"]])
#      |> Enum.each(fn target ->
#        assert target == Type.normalize(target)
#      end)
#    end
#  end
#
#  describe "for integers" do
#    test "integers don't need to be normalized" do
#      assert 47 == Type.normalize(47)
#    end
#
#    test "ranges don't need to be normalized" do
#      assert 42..47 == Type.normalize(42..47)
#    end
#  end
#
#  describe "floats" do
#    test "are normalized to float" do
#      assert float() == Type.normalize(47.0)
#    end
#  end
#
#  describe "atoms" do
#    test "don't need to be normalized" do
#      assert :foo == Type.normalize(:foo)
#    end
#  end
#
#  describe "top-arity functions" do
#    test "are normalized to any... functions" do
#      refute type((any() -> any())) == type((_ -> any()))
#      assert type((any() -> any())) == Type.normalize(type((_ -> any())))
#
#      # with a non-"any" return type
#      refute type((any() -> :foo)) ==
#        type((_ -> :foo))
#      assert type((any() -> :foo)) ==
#        Type.normalize(type((_ -> :foo)))
#
#      # with more than 1 arity
#      refute type((any(), any() -> any())) ==
#        type((_, _ -> any()))
#      assert type((any(), any() -> any())) ==
#        Type.normalize(type((_, _ -> any())))
#    end
#  end
#
#  describe "functions with literals" do
#    test "in the parameters can be normalized" do
#      assert type((remote(String.t) -> :ok)) ==
#        Type.normalize(type(("foo" -> :ok)))
#    end
#    test "in the return can be normalized" do
#      assert type((any() -> remote(String.t))) ==
#        Type.normalize(type((any() -> "foo")))
#
#      assert type((any(), any() -> remote(String.t))) ==
#        Type.normalize(type((_, _ -> "foo")))
#
#      assert type((... -> remote(String.t))) ==
#        Type.normalize(type((... -> "foo")))
#    end
#  end
#
#  describe "min-arity tuples" do
#    test "are normalized to general tuples" do
#      refute tuple() == tuple({any(), any(), any(), ...})
#      assert tuple() == Type.normalize(tuple({any(), any(), any(), ...}))
#    end
#  end
#
#  describe "maps with literals" do
#    test "are normalized correctly" do
#      assert type(%{optional(remote(String.t())) => remote(String.t())}) ==
#        Type.normalize(literal(%{"foo" => "bar"}))
#
#      assert type(%{foo: remote(String.t())}) ==
#        Type.normalize(literal(%{foo: "bar"}))
#    end
#  end
#
#  describe "tuples with literals" do
#    test "are normalized down to the expected type" do
#      assert tuple({remote(String.t)}) == Type.normalize(tuple({"foo"}))
#    end
#  end
#
#  describe "literal lists" do
#    test "are normalized to list type" do
#      assert [] == Type.normalize([])
#      assert list(remote(String.t),...) == Type.normalize(["foo"])
#    end
#  end
#
#  describe "literal binaries and bitstrings" do
#    test "are normalized correctly" do
#      assert remote(String.t()) == Type.normalize("foo")
#      # not UTF-8 compliant:
#      assert %Type.Bitstring{size: 8} == Type.normalize(<<255::8>>)
#      assert %Type.Bitstring{size: 7} == Type.normalize(<<0::7>>)
#    end
#  end
#
#  describe "String.t/1" do
#    test "is normalized back to String.t" do
#      refute remote(String.t()) == remote(String.t(8))
#      assert remote(String.t) == Type.normalize(remote(String.t(8)))
#    end
#  end
#
#  describe "unions of literals" do
#    test "are normalized correctly" do
#      assert remote(String.t()) == Type.normalize(Type.union("foo", "quux"))
#    end
#  end
#end
#
