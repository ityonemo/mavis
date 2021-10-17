defmodule TypeTest.Type.Inspect.TuplesTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  @source TypeTest.TypeExample.Tuples

  test "empty tuple" do
    assert "tuple({})" == inspect_type(@source, :empty_literal)
  end

  test "ok tuple literal" do
    assert "tuple({:ok, any()})" == inspect_type(@source, :ok_literal)
  end

  test "tuple type" do
    assert "tuple()" == inspect_type(@source, :tuple_type)
  end

  test "mfa" do
    assert "mfa()" == inspect_type(@source, :mfa_type)
  end
end
