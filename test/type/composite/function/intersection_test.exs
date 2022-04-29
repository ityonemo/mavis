defmodule TypeTest.TypeFunction.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection
  @moduletag :function

  import Type, only: :macros
  alias Type.Function

  @any_function function()
  @zero_arity_any type(( -> any()))
  @one_arity_any type((any() -> any()))
  @two_arity_any type((any(), any() -> any()))

  describe "the any function" do
    test "intersects with any and self" do
      assert @any_function == @any_function <~> any()
      assert @any_function == any() <~> @any_function

      assert @any_function == @any_function <~> @any_function
    end

    test "matches the arity of parameters" do
      # zero arity
      assert @zero_arity_any == @any_function <~> @zero_arity_any
      # one arity
      assert @one_arity_any == @any_function <~> @one_arity_any
      # two arity
      assert @two_arity_any == @any_function <~> @two_arity_any

      # arbitrary params
      assert type((integer() -> any())) == @any_function <~> type((integer() -> any()))
    end

    test "reduces return" do
      assert type((... -> integer())) == @any_function <~> type((... -> integer()))
    end

    test "reduces both" do
      assert type((integer() -> integer())) == @any_function <~> type((integer() -> integer()))
    end

    test "intersects with nothing else" do
      [type(( -> 0))]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == @any_function <~> target
      end)
    end
  end

  describe "a function with any parameters" do
    @any_with_integer type((... -> integer()))
    test "intersects with self and the any function" do
      assert @any_with_integer == @any_with_integer <~> @any_with_integer
      assert @any_with_integer == @any_with_integer <~> @any_function
    end

    test "matches the arity of parameters" do
      # zero arity
      assert type(( -> integer())) == @any_with_integer <~> @zero_arity_any
      # one arity
      assert type((any() -> integer())) == @any_with_integer <~> @one_arity_any
      # two arity
      assert type((any(), any() -> integer())) == @any_with_integer <~> @two_arity_any
      # arbitrary params

      assert type((integer() -> integer())) == @any_with_integer <~> type((integer() -> integer()))
    end

    test "reduces return" do
      assert type((any() -> 1..10)) == @any_with_integer <~> type((any() -> 1..10))
    end

    test "reduces both" do
      assert type((integer() -> 1..10)) == @any_with_integer <~> type((integer() -> 1..10))
    end

    test "is none if the returns don't match" do
      assert none() == @any_with_integer <~> type((any() -> atom()))
    end
  end

  describe "an n-arity function" do
    @three_arity type((_, _, _ -> any() ))
    test "intersects with itself, any, and the any function" do
      assert @three_arity = @three_arity <~> @three_arity
      assert @three_arity = @three_arity <~> any()
      assert @three_arity = @three_arity <~> @any_function
    end

    test "intersects with a function with the same arity" do
      assert type((_, _, _ -> integer())) == @three_arity <~> type((_, _, _ -> integer()))
      assert type((any(), any(), any() -> integer())) == @three_arity <~> type((any(), any(), any() -> integer()))
    end

    test "has no intersection with a function of another arity" do
      assert none() == @three_arity <~> type((_, _ -> any()))
      assert none() == @three_arity <~> type(( -> any()))
    end
  end

  describe "a function with defined parameters" do
    test "intersects with self and the any function" do
      # zero arity
      assert @zero_arity_any == @zero_arity_any <~> @any_function
      assert @zero_arity_any == @zero_arity_any <~> @zero_arity_any

      # one arity
      assert @one_arity_any == @one_arity_any <~> @any_function
      assert @one_arity_any == @one_arity_any <~> @one_arity_any

      # two arity
      assert @two_arity_any == @two_arity_any <~> @any_function
      assert @two_arity_any == @two_arity_any <~> @two_arity_any
    end

    test "must match arities" do
      assert none() == @zero_arity_any <~> @one_arity_any
      assert none() == @zero_arity_any <~> @two_arity_any
      assert none() == @one_arity_any <~> @two_arity_any
    end

    test "reduces the return type" do
      assert type(( -> integer())) == @zero_arity_any <~> type(( -> integer()))

      assert type((any() -> integer())) == @one_arity_any <~> type((any() -> integer()))

      assert type((any(), any() -> integer())) == @two_arity_any <~> type((any(), any() -> integer()))
    end

    test "must match parameter types" do
      assert none() == @one_arity_any <~> type((integer() -> any()))
      assert none() == @two_arity_any <~> type((integer(), any() -> any()))
      assert none() == @two_arity_any <~> type((any(), atom() -> any()))
    end

    test "is invalid if return mismatches" do
      assert none() == type((any() -> integer())) <~> type((any() -> atom()))
    end

    test "parameter types can span" do
      one_arity_a = type(((:foo | :bar) -> -5..5))
      one_arity_b = type((:foo -> 0..10) ||| (:bar -> 1..10))
      one_arity_c = type((:foo -> 0..5) ||| (:bar -> 1..5))
      
      assert one_arity_c == one_arity_a <~> one_arity_b
    end
  end
end
