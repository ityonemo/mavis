defmodule TypeTest.Type.Inspect.FunctionsTest do
  use ExUnit.Case, async: true
  import TypeTest.InspectCase

  import Type, only: :macros

  @moduletag :inspect

  @source TypeTest.TypeExample.Functions

  test "zero arity" do
    assert "( -> any())" == inspect_type(@source, :zero_arity)
  end

  test "two arity" do
    assert "(integer(), atom() -> float())" == inspect_type(@source, :two_arity)
  end

  test "any arity" do
    assert "(... -> integer())" == inspect_type(@source, :any_to_integer)
  end

  test "top arity 1 function" do
    assert "(_ -> any())" == inspect %Type.Function{params: 1, return: any()}
  end

  test "top arity 2 function" do
    assert "(_, _ -> any())" == inspect %Type.Function{params: 2, return: any()}
  end

  test "function" do
    assert "function()" == inspect_type(@source, :function_type)
  end

  defp inspect_spec(name) do
    {:ok, specs} = TypeTest.SpecExample
    |> Code.Typespec.fetch_specs

    specs
    |> Enum.find_value(fn
      {{^name, _}, [spec]} -> spec
      _ -> false
    end)
    |> Type.Spec.parse()
    |> inspect
  end

  test "function with when statement" do
    assert "(t -> t when t: var)" == inspect_spec(:when_var_1)
    assert "(t1, t2 -> t1 | t2 when t1: var, t2: var)" == inspect_spec(:when_var_2)
  end

  test "function with when statement and consntraint" do
    assert "(t -> t when t: integer())" == inspect_spec(:when_var_3)
  end
end
