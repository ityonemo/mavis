defmodule TypeTest.BuiltinBinary.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the binary type" do
    pull_types(defmodule Binary do
      @type binary_type :: binary
    end)

    test "looks like an binary" do
      assert "binary()" == inspect(@binary_type)
    end

    test "code translates correctly" do
      assert @binary_type == eval_inspect(@binary_type)
    end
  end
end
