defmodule TypeTest.Type.FetchType.TuplesTest do
  use ExUnit.Case, async: true
  @moduletag :fetch

  import Type, only: :macros

  @source TypeTest.TypeExample.Tuples

  alias Type.Tuple

  test "empty tuple" do
    assert {:ok, tuple({})}
      == Type.fetch_type(@source, :empty_literal)
  end

  test "ok tuple literal" do
    assert {:ok, tuple({:ok, builtin(:any)})}
      == Type.fetch_type(@source, :ok_literal)
  end

  test "tuple type" do
    assert {:ok, builtin(:tuple)}
      == Type.fetch_type(@source, :tuple_type)
  end

  test "mfa" do
    assert {:ok, tuple({builtin(:module), builtin(:atom), 0..255})}
      == Type.fetch_type(@source, :mfa_type)
  end
end
