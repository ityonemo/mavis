defmodule TypeTest.Type.FetchSpec.EtcTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.SpecCase

  alias Type.Message

  @moduletag :fetch

  @unions TypeTest.SpecExample.Unions
  @remote TypeTest.SpecExample.Remote

  test "union (of atoms)" do
    assert {:ok, identity_for(:foo <|> :bar)} == Type.fetch_spec(@unions, :of_atoms, 1)
  end

  describe "remote type" do
    test "basic case" do
      assert {:ok, identity_for(%Type{module: String, name: :t})} ==
        Type.fetch_spec(@remote, :elixir_string, 1)
    end
    test "with arity" do
      assert {:ok, identity_for(%Type{module: Foo, name: :bar, params: [builtin(:integer)]})} ==
        Type.fetch_spec(@remote, :foobar, 1)
    end
  end

  @type not_compiled :: integer

  test "types not compiled" do
    assert {:error, _} = Type.fetch_spec(__MODULE__, :not_compiled, 1)
  end

  test "nonexistent module" do
    assert {:error, _} = Type.fetch_spec(FooBarBaz, :not_amodule, 1)
  end

  test "spec not provided" do
    assert :unknown = Type.fetch_spec(TypeTest.SpecExample, :no_spec, 1)
  end

  test "nonexistent function" do
    assert {:error, _} = Type.fetch_spec(@unions, :nonexistent, 1)
  end

  test "wrong arity" do

  end
end
