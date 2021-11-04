defmodule TypeTest.LiteralInteger.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the literal integer type" do
    pull_types(defmodule LiteralInteger do
      @type literal_integer :: 47
    end)

    test "looks like a integer" do
      assert "47" == inspect(@literal_integer)
    end

    test "code translates correctly" do
      assert @literal_integeer == eval_inspect(@literal_integer)
    end
  end
end
