defmodule TypeTest.TypeFunctionVar.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  # warning: I'm not entirely sure this is the right way to handle
  # this, but it's hard to tell until more code is built around it.

  import Type, only: :macros
  use Type.Operators

  alias Type.Function.Var


  @any_var %Var{name: :foo}
  @bar_var %Var{name: :bar}
  @int_var %Var{name: :foo, constraint: integer()}

  describe "any variables" do
    test "are usable as itself and any" do
      assert :ok = @any_var ~> @any_var
      assert :ok = @any_var ~> any()
      assert :ok = any() ~> @any_var
      assert :ok = @bar_var ~> @any_var
    end
  end

  describe "integer variables" do
    test "are usable as itself and any" do
      assert :ok = @int_var ~> @int_var
      assert :ok = @int_var ~> any()
      assert :ok = integer() ~> @int_var
    end

    test "can take integer subtypes" do
      assert :ok = 1..10 ~> integer()
    end
  end
end
