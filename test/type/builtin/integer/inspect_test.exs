defmodule TypeTest.BuiltinInteger.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the integer type" do
    pull_types(defmodule Integer do
      @type integer_type :: integer
      @type integer_plus :: integer | nil
    end)

    test "looks like a integer" do
      assert "integer()" == inspect(@integer_type)
    end

    test "code translates correctly" do
      assert @integer_type == eval_inspect(@integer_type)
    end

    test "integer plus works" do
      assert "integer() <|> nil" = inspect(@integer_plus)
    end
  end
end
