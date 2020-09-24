defmodule TypeTest.TypeFunction.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Function

  @any_function %Function{params: :any, return: builtin(:any)}

  describe "the any function" do
    test "is a subtype of itself and any" do
      assert @any_function ~> @any_function
      assert @any_function ~> builtin(:any)
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([])
      |> Enum.each(fn target ->
        refute @any_function in target
      end)
    end
  end

  describe "for a defined return function" do
    test "is a subtype when the return is a subtype" do
      assert %Function{params: :any, return: :foo} in
        %Function{params: :any, return: builtin(:atom)}
    end

    test "is not a subtype when the return is not a subtype" do
      refute %Function{params: :any, return: :foo} in
        %Function{params: :any, return: builtin(:integer)}
    end
  end

  describe "when the parameters are defined" do
    test "they are subtypes when the parameters match and the return matches" do
      assert %Function{params: [builtin(:integer)], return: builtin(:integer)} in
        %Function{params: [builtin(:integer)], return: builtin(:any)}
    end

    test "they are not subtypes when the returns don't match" do
      refute %Function{params: [builtin(:integer)], return: builtin(:any)} in
        %Function{params: [builtin(:integer)], return: builtin(:integer)}
    end

    test "they are not subtypes when the params are not equal" do
      refute %Function{params: [builtin(:integer)], return: builtin(:any)} in
        %Function{params: [builtin(:pos_integer)], return: builtin(:any)}

      refute %Function{params: [builtin(:pos_integer)], return: builtin(:any)} in
        %Function{params: [builtin(:integer)], return: builtin(:any)}
    end

    test "they are not subtypes when the param lengths are not equal" do
      refute %Function{params: [builtin(:integer)], return: builtin(:any)} in
        %Function{params: [builtin(:integer), builtin(:integer)], return: builtin(:any)}
    end
  end
end
