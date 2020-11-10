defmodule TypeTest.Type.FetchSpec.FunctionsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  @source TypeTest.SpecExample.Functions

  import TypeTest.SpecCase

  alias Type.Function

  test "zero arity" do
    assert {:ok, identity_for(function(( -> builtin(:any))))} ==
      Type.fetch_spec(@source, :zero_arity_spec, 1)
  end

  test "two arity" do
    assert {:ok, identity_for(function((builtin(:integer), builtin(:atom) ->
                                        builtin(:float))))} ==
      Type.fetch_spec(@source, :two_arity_spec, 1)
  end

  @any_fn function((... -> builtin(:any)))

  test "any arity" do
    assert {:ok, identity_for(function((... -> builtin(:integer))))} ==
      Type.fetch_spec(@source, :any_arity_spec, 1)
  end

  test "fun" do
    assert {:ok, identity_for(@any_fn)} == Type.fetch_spec(@source, :fun_spec, 1)
  end

  test "function" do
    assert {:ok, identity_for(@any_fn)} == Type.fetch_spec(@source, :function_spec, 1)
  end
end
