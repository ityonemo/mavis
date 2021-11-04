defmodule TypeTest.BuiltinByte.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the byte type" do
    pull_types(defmodule Byte do
      @type byte_type :: byte
    end)

    test "looks like 0..255" do
      # as this is a strict synonym, we don't want to assume what the
      # user intent is.
      assert "0..255" == inspect(@byte_type)
    end

    test "evaluates correctly" do
      assert @byte_type == eval_type_str("byte()")
    end
  end
end
