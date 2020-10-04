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
      assert @any_function == Type.intersection(@any_function, @any)
      assert @any_function == Type.intersection(@any_function, @any_function)
    end

    test "matches the arity of parameters" do
      # zero arity
      assert @zero_arity_any == Type.intersection(@any_function, @zero_arity_any)
      # one arity
      assert @one_arity_any == Type.intersection(@any_function, @one_arity_any)
      # two arity
      assert @two_arity_any == Type.intersection(@any_function, @two_arity_any)

      # arbitrary params
      assert %Function{params: [builtin(:integer)], return: @any} ==
        Type.intersection(@any_function, %Function{params: [builtin(:integer)], return: @any})
    end

    test "reduces return" do
      assert %Function{params: :any, return: builtin(:integer)} ==
        Type.intersection(@any_function, %Function{params: :any, return: builtin(:integer)})
    end

    test "reduces both" do
      assert %Function{params: [builtin(:integer)], return: builtin(:integer)} ==
        Type.intersection(@any_function, %Function{params: [builtin(:integer)], return: builtin(:integer)})
    end

    test "intersects with nothing else" do
      TypeTest.Targets.except([%Function{params: [], return: 0}])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(@any_function, target)
      end)
    end
  end
end
