defmodule TypeTest.TypeFunction.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

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

    test "is not a subtype of a top function or a specific function" do
      refute @any_function in function((_ -> builtin(:any)))
      refute @any_function in function((builtin(:any) -> builtin(:any)))
    end
  end

  describe "for a top function" do
    test "it's a subtype of the any function" do
      assert function((_ -> :foo)) in function((... -> builtin(:atom)))
      assert function((_, _ -> :foo)) in function((... -> builtin(:atom)))
    end

    test "it's a subtype of the top similar function" do
      assert function((_ -> :foo)) in function((_ -> builtin(:atom)))
      assert function((_, _ -> :foo)) in function((_, _ -> builtin(:atom)))
    end

    test "is not a subtype of a top function or a specific function" do
      refute function((_ -> builtin(:any))) in function((builtin(:any) -> builtin(:any)))
    end
  end

  describe "when the parameters are defined" do
    test "they are subtypes of the any function and the top function" do
      assert function((builtin(:atom) -> builtin(:integer))) in
        function((_ -> builtin(:integer)))
      assert function((builtin(:atom) -> builtin(:integer))) in
        function((... -> builtin(:integer)))

      assert function((:ok, builtin(:integer) -> builtin(:atom))) in
        function((_, _ -> builtin(:atom)))
      assert function((:ok, builtin(:integer) -> builtin(:atom))) in @any_function
    end

    test "they are subtypes when the parameters match and the return matches" do
      assert function((builtin(:integer) -> builtin(:integer))) in
        function((builtin(:integer) -> builtin(:any)))
    end

    test "they are not subtypes when the returns don't match" do
      refute function((builtin(:integer) -> builtin(:any))) in
        function((builtin(:integer) -> builtin(:integer)))

      refute function((builtin(:atom) -> builtin(:any))) in
        function((_ -> builtin(:integer)))
      refute function((builtin(:atom) -> builtin(:any))) in
        function((... -> builtin(:integer)))
    end

    test "they are not subtypes when the param is a supertype" do
      assert function((builtin(:integer) -> builtin(:any))) in
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
