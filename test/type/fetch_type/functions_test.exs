defmodule TypeTest.Type.FetchType.FunctionsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  @source TypeTest.TypeExample.Functions

  alias Type.Function

  test "zero arity" do
    assert {:ok, %Function{params: [], return: any()}} ==
      Type.fetch_type(@source, :zero_arity)
  end

  test "two arity" do
    assert {:ok, %Function{params: [integer(), atom()], return: float()}} ==
      Type.fetch_type(@source, :two_arity)
  end

  @any_fn %Function{params: :any, return: any()}

  test "any arity" do
    assert {:ok, @any_fn} == Type.fetch_type(@source, :any_arity)
  end

  test "fun" do
    assert {:ok, @any_fn} == Type.fetch_type(@source, :fun_type)
  end

  test "function" do
    assert {:ok, @any_fn} == Type.fetch_type(@source, :function_type)
  end
end
