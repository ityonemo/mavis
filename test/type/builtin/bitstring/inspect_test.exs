defmodule TypeTest.BuiltinBitstring.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the bitstring type" do
    pull_types(defmodule Bitstring do
      @type bitstring_type :: bitstring
    end)

    test "looks like an bitstring" do
      assert "bitstring()" == inspect(@bitstring_type)
    end

    test "code translates correctly" do
      assert @bitstring_type == eval_inspect(@bitstring_type)
    end
  end
end
