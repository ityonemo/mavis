defmodule TypeTest.TypeFunction.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros
  alias Type.Function

  @any builtin(:any)
  @any_function function((... -> @any))
  @zero_arity_any function(( -> @any))
  @one_arity_any function((@any -> @any))
  @two_arity_any function((@any, @any -> @any))

  describe "the any function" do
    test "intersects with any and self" do
      assert @any_function == @any_function <~> @any
      assert @any_function == @any <~> @any_function

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
      assert function((builtin(:integer) -> @any)) ==
        @any_function <~> function((builtin(:integer) -> @any))
    end

    test "reduces return" do
      assert function((... -> builtin(:integer))) ==
        @any_function <~> function((... -> builtin(:integer)))
    end

    test "reduces both" do
      assert function((builtin(:integer) -> builtin(:integer))) ==
        @any_function <~> function((builtin(:integer) -> builtin(:integer)))
    end

    test "intersects with nothing else" do
      TypeTest.Targets.except([function(( -> 0))])
      |> Enum.each(fn target ->
        assert builtin(:none) == @any_function <~> target
      end)
    end
  end

  describe "a function with any parameters" do
    @any_with_integer function((... -> builtin(:integer)))
    test "intersects with self and the any function" do
      assert @any_with_integer == @any_with_integer <~> @any_with_integer
      assert @any_with_integer == @any_with_integer <~> @any_function
    end

    test "matches the arity of parameters" do
      # zero arity
      assert function(( -> builtin(:integer))) ==
          @any_with_integer <~> @zero_arity_any
      # one arity
      assert function((@any -> builtin(:integer))) ==
          @any_with_integer <~> @one_arity_any
      # two arity
      assert function((@any, @any -> builtin(:integer))) ==
          @any_with_integer <~> @two_arity_any

      # arbitrary params
      assert function((builtin(:integer) -> builtin(:integer))) ==
        @any_with_integer <~> function((builtin(:integer) -> @any))
    end

    test "reduces return" do
      assert function((... -> 1..10)) ==
        @any_with_integer <~> function((... -> 1..10))
    end

    test "reduces both" do
      assert function((builtin(:integer) -> 1..10)) ==
        @any_with_integer <~> function((builtin(:integer) -> 1..10))
    end

    test "is none if the returns don't match" do
      assert builtin(:none) == @any_with_integer <~>
        function((... -> builtin(:atom)))
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
      assert builtin(:none) == @zero_arity_any <~> @one_arity_any
      assert builtin(:none) == @zero_arity_any <~> @two_arity_any
      assert builtin(:none) == @one_arity_any <~> @two_arity_any
    end

    test "reduces the return type" do
      assert function(( -> builtin(:integer))) ==
        @zero_arity_any <~> function(( -> builtin(:integer)))

      assert function((@any -> builtin(:integer))) ==
        @one_arity_any <~> function((@any -> builtin(:integer)))

      assert function((@any, @any -> builtin(:integer))) ==
        @two_arity_any <~> function((@any, @any -> builtin(:integer)))
    end

    test "expands to the biggest parameters" do
      assert @one_arity_any == @one_arity_any <~> function((builtin(:integer) -> @any))

      assert @two_arity_any == @two_arity_any <~> function((builtin(:integer), @any -> @any))

      assert @two_arity_any == @two_arity_any <~> function((@any, builtin(:atom) -> @any))
    end

    test "is invalid if return mismatches" do
      assert builtin(:none) ==
        function((@any -> builtin(:integer))) <~>
        function((@any -> builtin(:atom)))
    end

    test "expands to parameter unions on mismatches" do
      assert function((builtin(:integer) <|> builtin(:atom) -> @any))  ==
        function((builtin(:integer) -> @any)) <~>
        function((builtin(:atom) -> @any))

      assert function((builtin(:integer) <|> builtin(:atom), @any -> @any)) ==
        function((builtin(:integer), @any -> @any)) <~>
        function((builtin(:atom), @any -> @any))

      assert function((@any, builtin(:integer) <|> builtin(:atom) -> @any)) ==
        function((@any, builtin(:integer) -> @any)) <~>
        function((@any, builtin(:atom) -> @any))
    end
  end

  describe "the arity-n top type" do
    @one_arity_top function((_ -> builtin(:any)))
    @two_arity_top function((_, _ -> builtin(:any)))
    test "intersects with self and the any function" do
      # one arity
      assert @one_arity_top == @one_arity_top <~> @any_function
      assert @one_arity_top == @one_arity_top <~> @one_arity_top

      # two arity
      assert @two_arity_top == @two_arity_top <~> @any_function
      assert @two_arity_top == @two_arity_top <~> @two_arity_top
    end

    test "must match arities" do
      assert builtin(:none) == @one_arity_top <~> @two_arity_top
      assert builtin(:none) == @one_arity_top <~> @two_arity_any
      assert builtin(:none) == @one_arity_any <~> @two_arity_top
    end

    test "reduces the return type" do
      assert function((_ -> builtin(:integer))) ==
        @one_arity_top <~> function((_ -> builtin(:integer)))

      assert function((@any -> builtin(:integer))) ==
        @one_arity_any <~> function((_ -> builtin(:integer)))
    end

    test "is invalid if return mismatches" do
      assert builtin(:none) ==
        function((_ -> builtin(:integer))) <~>
        function((_ -> builtin(:atom)))
    end
  end

end
