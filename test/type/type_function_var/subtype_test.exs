defmodule TypeTest.TypeFunctionVar.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.Function.Var


  @any_var %Var{name: :foo}
  @int_var %Var{name: :foo, constraint: integer()}

  describe "the any variable" do
    test "is a subtype of itself and any" do
      assert @any_var in @any_var
      assert @any_var in any()
    end

    test "any is a subtype of any variable" do
      assert any() in @any_var
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([])
      |> Enum.each(fn target ->
        refute @any_var in target
      end)
    end
  end

  describe "the integer-constrained variable" do
    test "is a subtype of integer" do
      assert @int_var in integer()
    end

    test "is a supertype of integer types" do
      #assert pos_integer() in @int_var
      assert 1..10 in @int_var
    end
  end
end
