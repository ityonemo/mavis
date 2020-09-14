defmodule TypeTest.TypeFunction.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Function

  defp param_fn(params, return) do
    %Function{params: params, return: return}
  end

  describe "a parameterized function" do
    test "is bigger than bottom and reference" do
      assert param_fn([], builtin(:any)) > builtin(:none)
      assert param_fn([], builtin(:any)) > builtin(:reference)
    end

    test "is bigger than a function with a less general return" do
      assert param_fn([], builtin(:any)) > param_fn([], builtin(:integer))
    end

    test "is smaller than a function with a more general return" do
      assert param_fn([], builtin(:integer)) < param_fn([], builtin(:any))
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert param_fn([], builtin(:any)) < builtin(:port)
      assert param_fn([], builtin(:any)) < builtin(:any)
    end
  end

  defp param_any_fn(return) do
    %Function{return: return, params: :any}
  end

  describe "a params any function" do
    test "is bigger than bottom and reference" do
      assert param_any_fn(builtin(:any)) > builtin(:none)
      assert param_any_fn(builtin(:any)) > builtin(:reference)
    end

    test "is bigger than a function with a less general return" do
      assert param_any_fn(builtin(:any)) > param_any_fn(builtin(:integer))
    end

    test "is smaller than a function with a more general return" do
      assert param_any_fn(builtin(:integer)) < param_any_fn(builtin(:any))
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert param_any_fn(builtin(:any)) < builtin(:port)
      assert param_any_fn(builtin(:any)) < builtin(:any)
    end
  end

end
