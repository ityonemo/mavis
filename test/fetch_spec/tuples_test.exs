defmodule TypeTest.Type.FetchSpec.TuplesTest do
  use ExUnit.Case, async: true
  @moduletag :fetch

  import Type, only: :macros

  import TypeTest.SpecCase

  @source TypeTest.SpecExample.Tuples

  test "empty tuple" do
    assert {:ok, identity_for(tuple({}))}
      == Type.fetch_spec(@source, :empty_literal_spec, 1)
  end

  test "ok tuple literal" do
    assert {:ok, identity_for(tuple({:ok, any()}))}
      == Type.fetch_spec(@source, :ok_literal_spec, 1)
  end

  test "tuple type" do
    assert {:ok, identity_for(tuple())}
      == Type.fetch_spec(@source, :tuple_spec, 1)
  end

  test "mfa" do
    assert {:ok, identity_for(tuple({module(), atom(), 0..255}))}
      == Type.fetch_spec(@source, :mfa_spec, 1)
  end
end
