defmodule TypeTest.TypeFunction.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]
  alias Type.Function

  @any builtin(:any)
  @any_function %Function{params: :any, return: @any}
  @zero_arity_any %Function{params: [], return: @any}
  @one_arity_any %Function{params: [@any], return: @any}
  @two_arity_any %Function{params: [@any, @any], return: @any}

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
      assert %Function{params: [builtin(:integer)], return: @any} ==
        @any_function <~> %Function{params: [builtin(:integer)], return: @any}
    end

    test "reduces return" do
      assert %Function{params: :any, return: builtin(:integer)} ==
        @any_function <~> %Function{params: :any, return: builtin(:integer)}
    end

    test "reduces both" do
      assert %Function{params: [builtin(:integer)], return: builtin(:integer)} ==
        @any_function <~> %Function{params: [builtin(:integer)], return: builtin(:integer)}
    end

    test "intersects with nothing else" do
      TypeTest.Targets.except([%Function{params: [], return: 0}])
      |> Enum.each(fn target ->
        assert builtin(:none) == @any_function <~> target
      end)
    end
  end

  describe "a function with any parameters" do
    @any_with_integer %Function{params: :any, return: builtin(:integer)}
    test "intersects with self and the any function" do
      assert @any_with_integer == @any_with_integer <~> @any_with_integer
      assert @any_with_integer == @any_with_integer <~> @any_function
    end

    test "matches the arity of parameters" do
      # zero arity
      assert %Function{params: [], return: builtin(:integer)} ==
          @any_with_integer <~> @zero_arity_any
      # one arity
      assert %Function{params: [@any], return: builtin(:integer)} ==
          @any_with_integer <~> @one_arity_any
      # two arity
      assert %Function{params: [@any, @any], return: builtin(:integer)} ==
          @any_with_integer <~> @two_arity_any

      # arbitrary params
      assert %Function{params: [builtin(:integer)], return: builtin(:integer)} ==
        @any_with_integer <~> %Function{params: [builtin(:integer)], return: @any}
    end

    test "reduces return" do
      assert %Function{params: :any, return: 1..10} ==
        @any_with_integer <~> %Function{params: :any, return: 1..10}
    end

    test "reduces both" do
      assert %Function{params: [builtin(:integer)], return: 1..10} ==
        @any_with_integer <~> %Function{params: [builtin(:integer)], return: 1..10}
    end

    test "is none if the returns don't match" do
      assert builtin(:none) == @any_with_integer <~> %Function{params: :any, return: builtin(:atom)}
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
      assert %Function{params: [], return: builtin(:integer)} ==
        @zero_arity_any <~> %Function{params: [], return: builtin(:integer)}

      assert %Function{params: [@any], return: builtin(:integer)} ==
        @one_arity_any <~> %Function{params: [@any], return: builtin(:integer)}

      assert %Function{params: [@any, @any], return: builtin(:integer)} ==
        @two_arity_any <~> %Function{params: [@any, @any], return: builtin(:integer)}
    end

    test "is invalid if any parameter types mismatches" do
      assert builtin(:none) ==
        @one_arity_any <~> %Function{params: [builtin(:integer)], return: @any}

      assert builtin(:none) ==
        @two_arity_any <~> %Function{params: [builtin(:integer), @any], return: @any}

      assert builtin(:none) ==
        @two_arity_any <~> %Function{params: [@any, builtin(:atom)], return: @any}
    end

    test "is invalid if return mismatches" do
      assert builtin(:none) ==
        %Function{params: [@any], return: builtin(:integer)} <~>
        %Function{params: [@any], return: builtin(:atom)}
    end

    test "is invalid if any parameter mismatches" do
      assert builtin(:none) ==
        %Function{params: [builtin(:integer)], return: @any} <~>
        %Function{params: [builtin(:atom)], return: @any}

      assert builtin(:none) ==
        %Function{params: [builtin(:integer), @any], return: @any} <~>
        %Function{params: [builtin(:atom), @any], return: @any}

      assert builtin(:none) ==
        %Function{params: [@any, builtin(:integer)], return: @any} <~>
        %Function{params: [@any, builtin(:atom)], return: @any}
    end
  end

end
