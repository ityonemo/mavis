defmodule TypeTest.LiteralFloat.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the literal float type" do
    @literal_float Type.of(47.0)

    test "looks like a float" do
      assert "47.0" == inspect(@literal_float)
    end

    test "code translates correctly" do
      assert @literal_float == eval_inspect(@literal_float)
    end
  end
end
