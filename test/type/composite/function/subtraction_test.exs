defmodule TypeTest.TypeFunction.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :subtraction

  import Type, only: :macros
  alias Type.Function


  @any_function function()
  @zero_arity_any type(( -> any))
  @one_arity_any type((any -> any))
  @two_arity_any type((any, any -> any))
  @three_arity type((_, _, _ -> any))

  describe "subtracting from the any function" do
    test "is none for any and self" do
      assert none() == @any_function - any()
      assert none() == @any_function - @any_function
    end

    test "is trivial for functions in general" do
      assert %Type.Subtraction{
        base: @any_function,
        exclude: @three_arity} == @any_function - @three_arity

      assert %Type.Subtraction{
        base: @any_function,
        exclude: @zero_arity_any} == @any_function - @zero_arity_any
    end

    test "is itself for anything else" do
      type(( -> 0))
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert @any_function == @any_function - target
      end)
    end
  end

  describe "subtracting from function with any parameters" do
    @any_with_integer type((... -> integer))
    test "is none for any, itself and the any function" do
      assert none() == @any_with_integer - any()
      assert none() == @any_with_integer - @any_with_integer
      assert none() == @any_with_integer - @any_function
    end

    test "is trivial for functions which have subset or matching return" do
      assert %Type.Subtraction{
        base: @any_with_integer,
        exclude: type(( -> integer))} ==
          @any_with_integer - type(( -> integer))
    end

    test "does expected subtractions for returns" do
      assert type((... -> 1..6)) == type((... -> 1..10)) - type((... -> 7..10))
    end

    test "is unaffected if the return is disjoint" do
      assert @any_with_integer == @any_with_integer - type(( -> atom))
    end
  end

  describe "subtracting from n-arity function" do
    @three_arity_integer type((_, _, _ -> integer))
    test "is none for any, itself, and any function" do
      assert none() == @three_arity - any()
      assert none() == @three_arity - @any_function
      assert none() == @three_arity - @three_arity

      assert none() == @three_arity_integer - any()
      assert none() == @three_arity_integer - @any_function
      assert none() == @three_arity_integer - @three_arity
      assert none() == @three_arity_integer - @three_arity_integer
    end

    test "is trivial when the return is a subset" do
      assert %Type.Subtraction{
        base: @three_arity,
        exclude: @three_arity_integer
      } == @three_arity - @three_arity_integer
    end
  end

  describe "subtracting from a function with defined parameters" do
    test "is none for self and the any function" do
      # zero arity
      assert none() == @zero_arity_any - @any_function
      assert none() == @zero_arity_any - @zero_arity_any

      # one arity
      assert none() == @one_arity_any - @any_function
      assert none() == @one_arity_any - @one_arity_any

      # two arity
      assert none() == @two_arity_any - @any_function
      assert none() == @two_arity_any - @two_arity_any
    end

    test "is none for a matching n-arity function" do
      assert none() == type((any, any, any -> any)) - @three_arity
    end

    test "must match arities" do
      assert @zero_arity_any == @zero_arity_any - @one_arity_any
      assert @zero_arity_any == @zero_arity_any - @two_arity_any
      assert @one_arity_any == @one_arity_any - @two_arity_any
    end

    test "reduces the return type" do
      assert %Type.Subtraction{
        base: @zero_arity_any,
        exclude: type(( -> integer))} ==
        @zero_arity_any - type(( -> integer))

      assert %Type.Subtraction{
        base: @one_arity_any,
        exclude: type((any -> integer))} ==
        @one_arity_any - type((any -> integer))

      assert %Type.Subtraction{
        base: @two_arity_any,
        exclude: type((any, any -> integer))} ==
        @two_arity_any - type((any, any -> integer))
    end

    test "is invalid if any parameter types mismatches" do
      assert @one_arity_any == @one_arity_any - type((integer -> any))

      assert @two_arity_any == @two_arity_any - type((integer, any -> any))

      assert @two_arity_any == @two_arity_any - type((any, atom -> any))
    end

    test "is invalid if return mismatches" do
      assert type((any -> integer)) == type((any -> integer)) - type((any -> atom))
    end

    test "is invalid if any parameter mismatches" do
      assert type((integer -> any)) == type((integer -> atom)) - type((atom -> any))
      assert type((integer, any -> any)) == type((integer, any -> atom)) - type((atom, any -> any))
      assert type((any, integer -> any)) == type((any, integer -> atom)) - type((any, atom -> any))
    end
  end

end
