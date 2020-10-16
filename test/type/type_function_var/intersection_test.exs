defmodule TypeTest.TypeFunctionVar.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]
  alias Type.Function.Var

  @any builtin(:any)
  @any_var %Var{name: :foo}

  describe "the default variable" do
    test "intersects with any and self" do
      assert @any_var == @any_var <~> @any
      assert @any_var == @any <~> @any_var

      assert @any_var == @any_var <~> @any_var
    end

    test "performs an intersection" do
      assert %Var{constraint: builtin(:integer)} =
        @any_var <~> builtin(:integer)

      assert %Var{constraint: builtin(:integer)} =
        builtin(:integer) <~> @any_var
    end
  end

  @int_var %Var{name: :foo, constraint: builtin(:integer)}

  describe "a constrained variable" do
    test "becomes more constrained" do
      assert %Var{constraint: 1..10} =
        @int_var <~> 1..10

      assert %Var{constraint: 1..10} =
        1..10 <~> @int_var
    end
  end
end
