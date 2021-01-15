defmodule TypeTest.TypeFunction.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros
  alias Type.Function

  @any any()
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
      assert %Function{params: [integer()], return: @any} ==
        @any_function <~> %Function{params: [integer()], return: @any}
    end

    test "reduces return" do
      assert %Function{params: :any, return: integer()} ==
        @any_function <~> %Function{params: :any, return: integer()}
    end

    test "reduces both" do
      assert %Function{params: [integer()], return: integer()} ==
        @any_function <~> %Function{params: [integer()], return: integer()}
    end

    test "intersects with nothing else" do
      TypeTest.Targets.except([%Function{params: [], return: 0}])
      |> Enum.each(fn target ->
        assert none() == @any_function <~> target
      end)
    end
  end

  describe "a function with any parameters" do
    @any_with_integer %Function{params: :any, return: integer()}
    test "intersects with self and the any function" do
      assert @any_with_integer == @any_with_integer <~> @any_with_integer
      assert @any_with_integer == @any_with_integer <~> @any_function
    end

    test "matches the arity of parameters" do
      # zero arity
      assert %Function{params: [], return: integer()} ==
          @any_with_integer <~> @zero_arity_any
      # one arity
      assert %Function{params: [@any], return: integer()} ==
          @any_with_integer <~> @one_arity_any
      # two arity
      assert %Function{params: [@any, @any], return: integer()} ==
          @any_with_integer <~> @two_arity_any

      # arbitrary params
      assert %Function{params: [integer()], return: integer()} ==
        @any_with_integer <~> %Function{params: [integer()], return: @any}
    end

    test "reduces return" do
      assert %Function{params: :any, return: 1..10} ==
        @any_with_integer <~> %Function{params: :any, return: 1..10}
    end

    test "reduces both" do
      assert %Function{params: [integer()], return: 1..10} ==
        @any_with_integer <~> %Function{params: [integer()], return: 1..10}
    end

    test "is none if the returns don't match" do
      assert none() == @any_with_integer <~> %Function{params: :any, return: atom()}
    end
  end

  describe "an n-arity function" do
    @three_arity %Function{params: 3, return: any()}
    test "intersects with itself, any, and the any function" do
      assert @three_arity = @three_arity <~> @three_arity
      assert @three_arity = @three_arity <~> any()
      assert @three_arity = @three_arity <~> @any_function
    end

    test "intersects with a function with the same arity" do
      assert %Function{params: 3, return: integer()} ==
        @three_arity <~> %Function{params: 3, return: integer()}
      assert %Function{params: [any(), any(), any()], return: any()} ==
        @three_arity <~> %Function{params: [any(), any(), any()], return: any()}
    end

    test "has no intersection with a function of another arity" do
      assert none() == @three_arity <~> %Function{params: 2, return: any()}
      assert none() == @three_arity <~> %Function{params: [], return: any()}
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
      assert %Function{params: [], return: integer()} ==
        @zero_arity_any <~> %Function{params: [], return: integer()}

      assert %Function{params: [@any], return: integer()} ==
        @one_arity_any <~> %Function{params: [@any], return: integer()}

      assert %Function{params: [@any, @any], return: integer()} ==
        @two_arity_any <~> %Function{params: [@any, @any], return: integer()}
    end

    test "is invalid if any parameter types mismatches" do
      assert none() ==
        @one_arity_any <~> %Function{params: [integer()], return: @any}

      assert none() ==
        @two_arity_any <~> %Function{params: [integer(), @any], return: @any}

      assert none() ==
        @two_arity_any <~> %Function{params: [@any, atom()], return: @any}
    end

    test "is invalid if return mismatches" do
      assert none() ==
        %Function{params: [@any], return: integer()} <~>
        %Function{params: [@any], return: atom()}
    end

    test "is invalid if any parameter mismatches" do
      assert none() ==
        %Function{params: [integer()], return: @any} <~>
        %Function{params: [atom()], return: @any}

      assert none() ==
        %Function{params: [integer(), @any], return: @any} <~>
        %Function{params: [atom(), @any], return: @any}

      assert none() ==
        %Function{params: [@any, integer()], return: @any} <~>
        %Function{params: [@any, atom()], return: @any}
    end
  end

end
