defmodule TypeTest.Type.FetchType.EtcTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  alias Type.Message

  @moduletag :fetch

  @unions TypeTest.TypeExample.Unions
  @remote TypeTest.TypeExample.Remote

  test "union (of atoms)" do
    assert {:ok, (:foo <|> :bar)} == Type.fetch_type(@unions, :of_atoms)
  end

  describe "remote type" do
    test "basic case" do
      assert {:ok, %Type{module: String, name: :t}} ==
        Type.fetch_type(@remote, :elixir_string)
    end
    test "with arity" do
      assert {:ok, %Type{module: Foo, name: :bar, params: [builtin(:integer)]}} ==
        Type.fetch_type(@remote, :foobar)
    end
  end

  test "type with arity" do
    assert {:ok, builtin(:integer)} ==
      Type.fetch_type(@remote, :with_arity, [builtin(:integer)])
  end

  @type not_compiled :: integer

  test "types not compiled" do
    assert {:error, _} = Type.fetch_type(__MODULE__, :not_compiled)
  end

  test "nonexistent module" do
    assert {:error, _} = Type.fetch_type(FooBarBaz, :not_amodule)
  end

  test "nonexistent type" do
    assert {:error, msg} = Type.fetch_type(@unions, :nonexistent, 0, [file: "foo", line: 47])
    assert %Message{type:
      %Type{module: @unions, name: :nonexistent}
    } = msg
  end
end
