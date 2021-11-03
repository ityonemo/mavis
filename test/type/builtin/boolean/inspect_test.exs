defmodule TypeTest.BuiltinBoolean.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the boolean type" do
    pull_types(defmodule Boolean do
      @type boolean_type :: boolean
      @type boolean_plus :: boolean | nil
    end)

    test "looks like an boolean" do
      assert "boolean()" == inspect(@boolean_type)
    end

    test "code translates correctly" do
      assert @boolean_type == eval_inspect(@boolean_type)
    end

    test "boolean plus types" do
      assert "boolean() <|> nil" == inspect(@boolean_plus)
    end
  end
end
