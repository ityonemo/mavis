defmodule TypeTest.BuiltinNonNegInteger.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the non_neg_integer type" do
    pull_types(defmodule NonNegInteger do
      @type non_neg_integer_type :: non_neg_integer
      @type non_neg_integer_plus :: non_neg_integer | nil

    end)

    test "looks like a none" do
      assert "non_neg_integer()" == inspect(@non_neg_integer_type)
    end

    test "code translates correctly" do
      assert @non_neg_integer_type == eval_inspect(@non_neg_integer_type)
    end

    test "unions broken out correctly" do
      assert "non_neg_integer() <|> nil" == inspect(@non_neg_integer_plus)
    end
  end
end
