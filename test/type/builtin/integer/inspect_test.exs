defmodule TypeTest.BuiltinInteger.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase

  @moduletag :inspect

  pull_types(defmodule Integer do
    @type integer_type :: integer
    @type integer_plus :: integer | nil
  end)

  describe "the integer type" do
    test "looks like a integer" do
      assert "integer()" == inspect(@integer_type)
    end

    test "translates correctly" do
      assert @integer_type == eval_inspect(@integer_type)
    end
  end

  describe "integer union something else" do
    test "looks like an integer" do
      assert "integer() <|> nil" = inspect(@integer_plus)
    end

    test "integer_plus translates correctly" do
      assert @integer_plus == eval_inspect(@integer_plus)
    end
  end
end
