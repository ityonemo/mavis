defmodule TypeTest.TypeFunction.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.Function

  @any_function function((... -> builtin(:any)))

  describe "the any function" do
    test "is a subtype of itself and any" do
      assert @any_function in @any_function
      assert @any_function in builtin(:any)
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
      assert function((... -> :foo)) in
        function((... -> builtin(:atom)))
    end

    test "is not a subtype when the return is not a subtype" do
      refute function((... -> :foo)) in
        function((... -> builtin(:integer)))
    end
  end

  describe "when the parameters are defined" do
    test "they are subtypes when the parameters match and the return matches" do
      assert function((builtin(:integer) -> builtin(:integer))) in
        function((builtin(:integer) -> builtin(:any)))
    end

    test "they are not subtypes when the returns don't match" do
      refute function((builtin(:integer) -> builtin(:any))) in
        function((builtin(:integer) -> builtin(:integer)))
    end

    test "they are not subtypes when the params are not equal" do
      refute function((builtin(:integer) -> builtin(:any))) in
        function((builtin(:pos_integer) -> builtin(:any)))

      refute function((builtin(:pos_integer) -> builtin(:any))) in
        function((builtin(:integer) -> builtin(:any)))
    end

    test "they are not subtypes when the param lengths are not equal" do
      refute function((builtin(:integer) -> builtin(:any))) in
        function((builtin(:integer), builtin(:integer) -> builtin(:any)))
    end
  end
end
