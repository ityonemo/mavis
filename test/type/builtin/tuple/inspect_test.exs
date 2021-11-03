defmodule TypeTest.BuiltinTuple.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the tuple type" do
    pull_types(defmodule Tuple do
      @type tuple_type :: tuple
    end)

    test "looks like a none" do
      assert "tuple()" == inspect(@tuple_type)
    end

    test "code translates correctly" do
      assert @tuple_type == eval_inspect(@tuple_type)
    end
  end
end
