defmodule TypeTest.BuiltinNegInteger.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the neg_integer type" do
    pull_types(defmodule NegInteger do
      @type neg_integer_type :: neg_integer
    end)

    test "looks like a neg_integer" do
      assert "neg_integer()" == inspect(@neg_integer_type)
    end

    test "code translates correctly" do
      assert @neg_integer_type == eval_inspect(@neg_integer_type)
    end
  end
end
