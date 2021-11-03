defmodule TypeTest.BuiltinTimeout.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the timeout type" do
    pull_types(defmodule Timeout do
      @type timeout_type :: timeout
      @type timeout_plus :: timeout | nil

    end)

    test "looks like a none" do
      assert "timeout()" == inspect(@timeout_type)
    end

    test "code translates correctly" do
      assert @timeout_type == eval_inspect(@timeout_type)
    end

    test "unions broken out correctly" do
      assert "timeout() <|> nil" == inspect(@timeout_plus)
    end
  end
end
