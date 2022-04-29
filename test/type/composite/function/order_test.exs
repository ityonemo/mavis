defmodule TypeTest.TypeFunction.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order
  @moduletag :function

  import Type, only: :macros

  use Type.Operators

  defp param_any_fn(return) do
    type((... -> return))
  end

  describe "a params any function" do
    test "is bigger than bottom and reference" do
      assert param_any_fn(any()) > none()
      assert param_any_fn(any()) > reference()
    end

    test "is bigger than n-arity or defined parameter functions" do
      assert param_any_fn(any()) > type((_ -> any()))
      assert param_any_fn(any()) > type((integer() -> any()))
      assert param_any_fn(any()) > type((_, _ -> any()))
      assert param_any_fn(any()) > type((integer(), integer() -> any()))
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

    test "is smaller than ports or top" do
      assert param_any_fn(any()) < port()
      assert param_any_fn(any()) < any()
    end
  end

  describe "an n-arity function" do
    @arity_1_integer type((_ -> integer()))
    @arity_2_integer type((_, _ -> integer()))

    test "is bigger than bottom and reference" do
      assert @arity_1_integer > none()
      assert @arity_1_integer > reference()
      assert @arity_2_integer > none()
      assert @arity_2_integer > reference()
    end

    test "is bigger than a function with specified params" do
      assert @arity_1_integer > type((integer() -> integer()))
      assert @arity_2_integer > type((integer(), integer() -> integer()))
    end

    test "is bigger than a function with less general return" do
      assert @arity_1_integer > type((_ -> 0..10))
      assert @arity_2_integer > type((_, _ -> 0..10))
    end

    test "is smaller than a union containing it" do
      assert @arity_1_integer < 0 <|> @arity_1_integer
    end

    test "is smaller than an n-arity function with a more general return" do
      assert @arity_1_integer < type((_ -> any()))
      assert @arity_2_integer < type((_, _ -> any()))
    end

    test "is smaller than any arity function, or a bigger arity function" do
      assert @arity_1_integer < param_any_fn(integer())
      assert @arity_1_integer < @arity_2_integer
      assert @arity_1_integer < type((integer(), integer() -> integer()))
    end

    test "is smaller than ports or top" do
      assert @arity_1_integer < port()
      assert @arity_1_integer < any()

      assert @arity_2_integer < port()
      assert @arity_2_integer < any()
    end
  end

  describe "a function with params" do
    @integer_1_integer type((integer() -> integer()))
    @integer_2_integer type((integer(), integer() -> integer()))

    test "is bigger than bottom and reference" do
      assert @integer_1_integer > none()
      assert @integer_1_integer > reference()
      assert @integer_2_integer > none()
      assert @integer_2_integer > reference()
    end

    test "is bigger than a function with more general params" do
      assert @integer_1_integer > type((any() -> integer()))
      assert @integer_2_integer > type((any(), integer() -> integer()))
      assert @integer_2_integer > type((integer(), any() -> integer()))
    end

    test "is bigger than a function with an extra branch" do
      assert @integer_1_integer > type((integer() -> integer()) ||| (atom() -> atom()))
      assert @integer_2_integer > type((integer(), integer() -> integer()) ||| (integer(), atom() -> integer()))
      assert @integer_2_integer > type((integer(), integer() -> integer()) ||| (atom(), integer() -> integer()))
    end

    test "is bigger than a function with less general return" do
      assert @integer_1_integer > type((integer() -> 0..10))
      assert @integer_2_integer > type((integer(), integer -> 0..10))
    end

    test "is smaller than a union containing it" do
      assert @integer_1_integer < 0 <|> @integer_1_integer
    end

    test "is smaller than an n-arity function with less general params" do
      assert @integer_1_integer < type((1..10 -> any()))
      assert @integer_2_integer < type((1..10, integer() -> any()))
      assert @integer_2_integer < type((integer(), 1..10 -> any()))
    end

    test "is smaller than an n-arity function with a more general return" do
      assert @integer_1_integer < type((integer() -> any()))
      assert @integer_2_integer < type((integer(), integer() -> any()))
    end

    test "is smaller than any arity function, n-arity, or a bigger arity function" do
      assert @integer_1_integer < param_any_fn(integer())
      assert @integer_1_integer < @arity_1_integer
      assert @integer_1_integer < @integer_2_integer
      assert @integer_1_integer < type((integer(), integer() -> integer()))
    end

    test "is smaller than ports or top" do
      assert @integer_1_integer < port()
      assert @integer_1_integer < any()

      assert @integer_2_integer < port()
      assert @integer_2_integer < any()
    end
  end
end
