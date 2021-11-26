defmodule TypeTest.BuiltinChar.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the char type" do
    pull_types(defmodule Char do
      @type char_type :: char
    end)

    test "looks like 0..0x10_FFFF" do
      # as this is a strict synonym, we don't want to assume what the
      # user intent is.
      assert "0..1114111" == inspect(@char_type)
    end

    test "evaluates correctly" do
      assert @char_type == eval_type_str("char()")
    end
  end
end
