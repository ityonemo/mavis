defmodule TypeTest.TypeFunctionVar.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.Function.Var


  @any_var %Var{name: :foo}
  @bar_var %Var{name: :bar}

  describe "the any variable" do
    test "is smaller than the pure type" do
      assert @any_var < any()
      assert any() > @any_var
    end

    test "is bigger than all other types" do
      TypeTest.Targets.except([])
      |> Enum.each(fn target ->
        assert target < @any_var
        assert @any_var > target
      end)
    end
  end

  describe "the negative integer variable" do
    @neg_var %Var{name: :foo, constraint: neg_integer()}

    test "is smaller than the pure type" do
      assert @neg_var < neg_integer()
      assert neg_integer() > @neg_var
    end

    test "is bigger than the biggest negative integer" do
      assert @neg_var > -1
      assert -1 < @neg_var
    end

    test "is smaller than the smallest non negative integer" do
      assert @neg_var < 0
      assert 0 > @neg_var
    end
  end

  describe "when comparing two vars" do
    test "when the constraints are the same it's lexical" do
      assert @bar_var < @any_var
    end

    test "when the constraints are different it's constraint order" do
      assert @neg_var < @bar_var
    end
  end

end
