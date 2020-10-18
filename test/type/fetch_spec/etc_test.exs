defmodule TypeTest.Type.FetchSpec.EtcTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.SpecCase

  alias Type.Function

  @moduletag :fetch

  @unions TypeTest.SpecExample.Unions
  @remote TypeTest.SpecExample.Remote
  @example TypeTest.SpecExample

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
    assert :unknown = Type.fetch_spec(@example, :no_spec, 1)
  end

  test "nonexistent function" do
    assert {:error, _} = Type.fetch_spec(@unions, :nonexistent, 1)
  end

  test "wrong arity" do
    assert {:error, _} = Type.fetch_spec(@example, :valid_spec, 2)
  end

  alias Type.Function.Var

  test "with annotation" do
    assert {:ok, fun} = Type.fetch_spec(@example, :with_annotation, 1)
    assert %Function{params: [builtin(:any)], return: builtin(:any)} = fun
  end

  test "function with basic when statement" do
    assert {:ok, fun} = Type.fetch_spec(@example, :when_var_1, 1)

    assert %Function{
      params: [%Var{name: :t}],
      return: %Var{name: :t}
    } = fun
  end

  test "function with multiple when statement" do
    assert {:ok, fun} = Type.fetch_spec(@example, :when_var_2, 2)

    return_union = %Var{name: :t1} <|> %Var{name: :t2}

    assert %Function{
      params: [%Var{name: :t1}, %Var{name: :t2}],
      return: ^return_union
    } = fun
  end

  test "basic constrained function" do
    assert {:ok, fun} = Type.fetch_spec(@example, :basic_when_any, 1)

    assert %Function{
      params: [%Var{name: :t, constraint: builtin(:any)}],
      return: %Var{name: :t, constraint: builtin(:any)}
    } = fun
  end

  test "type constrained function" do
    assert {:ok, fun} = Type.fetch_spec(@example, :basic_when_int, 1)

    assert %Function{
      params: [%Var{name: :t, constraint: builtin(:integer)}],
      return: %Var{name: :t, constraint: builtin(:integer)}
    } = fun
  end

  test "type constrained result" do
    assert {:ok, fun} = Type.fetch_spec(@example, :basic_when_union, 1)

    type_union = %Var{name: :t, constraint: builtin(:integer)} <|> builtin(:atom)

    assert %Function{
      params: [%Var{name: :t, constraint: builtin(:integer)}],
      return: ^type_union
    } = fun
  end

  test "referring to a recursive type" do
    assert {:ok, spec} = Type.fetch_spec(@example, :basic_with_json, 1)

    json = %Type{module: @example, name: :json}

    assert %Function{params: [^json], return: ^json} = spec
  end
end
