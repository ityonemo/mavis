defmodule TypeTest.TypeFunction.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order
  @moduletag :function

  import Type, only: :macros

  use Type.Operators

  alias Type.Function

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
