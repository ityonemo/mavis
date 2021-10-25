defmodule TypeTest.LiteralRange.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the literal integer type" do
    pull_types(defmodule LiteralInteger do
      @type literal_range :: 1..47
    end)

    test "looks like a integer" do
      assert "1..47" == inspect(@literal_range)
    end

    test "code translates correctly" do
      assert @literal_range == eval_inspect(@literal_range)
    end
  end
end
