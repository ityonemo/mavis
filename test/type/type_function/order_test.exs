defmodule TypeTest.TypeFunction.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

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

    test "is bigger than a function with more parameters" do
      assert param_fn([], builtin(:any)) > param_fn([:foo], builtin(:any))
      assert param_fn([:foo], builtin(:any)) > param_fn([:bar, :baz], builtin(:any))
    end

    test "is bigger than a function with a less general parameter" do
      assert param_fn([builtin(:any)], builtin(:any)) >
        param_fn([builtin(:integer)], builtin(:any))
      assert param_fn([:foo, builtin(:any)], builtin(:any)) >
        param_fn([:foo, builtin(:integer)], builtin(:any))
    end

    test "is smaller than a function with a more general return" do
      assert param_fn([], builtin(:integer)) < param_fn([], builtin(:any))
    end

    test "is smaller than a function with fewer parameters" do
      assert param_fn([:foo], builtin(:any)) < param_fn([], builtin(:any))
      assert param_fn([:bar, :baz], builtin(:any)) < param_fn([:foo], builtin(:any))
    end

    test "is smaller than a function with a more general parameter" do
      assert param_fn([builtin(:integer)], builtin(:any)) <
        param_fn([builtin(:any)], builtin(:any))
      assert param_fn([:foo, builtin(:integer)], builtin(:any)) <
        param_fn([:foo, builtin(:any)], builtin(:any))
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

    test "is smaller than a union containing it" do
      assert param_any_fn(builtin(:any)) < 0 <|> param_any_fn(builtin(:any))
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
