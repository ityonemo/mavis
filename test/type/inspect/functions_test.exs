defmodule TypeTest.Type.FetchType.FunctionsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.InspectCase

  @moduletag :inspect

  @source TypeTest.TypeExample.Functions

  alias Type.Function

  test "zero arity" do
    assert "( -> any())" == inspect_type(@source, :zero_arity)
  end

  test "two arity" do
    assert "(integer(), atom() -> float())" == inspect_type(@source, :two_arity)
  end

  @any_fn %Function{params: :any, return: builtin(:any)}

  test "any arity" do
    assert "(... -> integer())" == inspect_type(@source, :any_to_integer)
  end

  test "function" do
    assert "function()" == inspect_type(@source, :function_type)
  end
end
