defmodule TypeTest.BuiltinReference.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the reference type" do
    pull_types(defmodule Reference do
      @type reference_type :: reference()
    end)

    test "is presented as itself" do
      assert "reference()" == inspect(@reference_type)
    end

    test "code translates correctly" do
      assert @reference_type == eval_inspect(@reference_type)
    end
  end
end
