defmodule TypeTest.TypeFunction.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order
  @moduletag :function

  import Type, only: :macros

  use Type.Operators

  alias Type.Function

  defp param_fn(params, return) do
    type((...(params) -> return))
  end

  describe "a parameterized function" do
    test "is bigger than bottom and reference" do
      assert param_fn([], any()) > none()
      assert param_fn([], any()) > reference()
    end

    test "is bigger than a function with a less general return" do
      assert param_fn([], any()) > param_fn([], integer())
    end

    test "is bigger than a function with more parameters" do
      assert param_fn([], any()) > param_fn([:foo], any())
      assert param_fn([:foo], any()) > param_fn([:bar, :baz], any())
    end

    test "is bigger than a function with a less general parameter" do
      assert param_fn([any()], any()) >
        param_fn([integer()], any())
      assert param_fn([:foo, any()], any()) >
        param_fn([:foo, integer()], any())
    end

    test "is smaller than a function with a more general return" do
      assert param_fn([], integer()) < param_fn([], any())
    end

    test "is smaller than a function with fewer parameters" do
      assert param_fn([:foo], any()) < param_fn([], any())
      assert param_fn([:bar, :baz], any()) < param_fn([:foo], any())
    end

    test "is smaller than a function with a more general parameter" do
      assert param_fn([integer()], any()) <
        param_fn([any()], any())
      assert param_fn([:foo, integer()], any()) <
        param_fn([:foo, any()], any())
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert param_fn([], any()) < port()
      assert param_fn([], any()) < any()
    end
  end

  defp param_any_fn(return) do
    type((... -> return))
  end

  describe "a params any function" do
    test "is bigger than bottom and reference" do
      assert param_any_fn(any()) > none()
      assert param_any_fn(any()) > reference()
    end

    test "is bigger than a function with a less general return" do
      assert param_any_fn(any()) > param_any_fn(integer())
    end

    test "is smaller than a union containing it" do
      assert param_any_fn(any()) < 0 <|> param_any_fn(any())
    end

    test "is smaller than a function with a more general return" do
      assert param_any_fn(integer()) < param_any_fn(any())
    end

    test "is smaller than maybe-empty lists, bitstrings or top" do
      assert param_any_fn(any()) < port()
      assert param_any_fn(any()) < any()
    end
  end

end
