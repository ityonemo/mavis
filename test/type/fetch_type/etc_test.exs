defmodule TypeTest.Type.FetchType.EtcTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  alias Type.Message

  @moduletag :fetch

  @unions TypeTest.TypeExample.Unions
  @remote TypeTest.TypeExample.Remote
  @example TypeTest.TypeExample

  test "union (of atoms)" do
    assert {:ok, (:foo <|> :bar)} == Type.fetch_type(@unions, :of_atoms)
  end

  describe "remote type" do
    test "basic case" do
      assert {:ok, %Type{module: String, name: :t}} ==
        Type.fetch_type(@remote, :elixir_string)
    end
    test "with arity" do
      assert {:ok, %Type{module: Foo, name: :bar, params: [integer()]}} ==
        Type.fetch_type(@remote, :foobar)
    end
  end

  describe "local type (:user_type)" do
    test "basic case" do
      # verify that the user_type type actually has the
      # erlang user_type keyword in it.

      {:ok, specs} = Code.Typespec.fetch_types(@example)
      assert {:user_type, _, _, _} = Enum.find_value(specs, fn
        {:type, {:user_type, typespec, []}} -> typespec
        _ -> false
      end)

      assert {:ok, %Type{module: @example, name: :other_type}} =
        Type.fetch_type(@example, :user_type)
    end
  end

  describe "private type" do
    test "basic case" do
      {:ok, specs} = Code.Typespec.fetch_types(@example)
      assert Enum.find(specs, &match?({:typep, {:typep, _, _}}, &1))

      assert {:ok, any()} = Type.fetch_type(@example, :typep)
    end
  end

  test "type with arity" do
    assert {:ok, integer()} ==
      Type.fetch_type(@remote, :with_arity, [integer()])
  end

  @type not_compiled :: integer

  test "types not compiled" do
    assert {:error, _} = Type.fetch_type(__MODULE__, :not_compiled)
  end

  test "nonexistent module" do
    assert {:error, _} = Type.fetch_type(FooBarBaz, :not_amodule)
  end

  test "nonexistent type" do
    assert {:error, msg} = Type.fetch_type(@unions, :nonexistent, [], [file: "foo", line: 47])
    assert %Message{type:
      %Type{module: @unions, name: :nonexistent}
    } = msg
  end
end
