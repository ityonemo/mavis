defmodule TypeTest.BuiltinFun.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the fun type" do
    pull_types(defmodule Fun do
      @type fun_type :: fun
    end)

    test "looks like function()" do
      # as this is a strict synonym, we don't want to assume what the
      # user intent is.
      assert "function()" == inspect(@fun_type)
    end

    test "evaluates correctly" do
      assert @fun_type == eval_type_str("fun()")
    end
  end
end