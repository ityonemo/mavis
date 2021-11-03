defmodule TypeTest.BuiltinArity.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the arity type" do
    pull_types(defmodule Arity do
      @type arity_type :: arity
    end)

    test "looks like 0..255" do
      # as this is a strict synonym, we don't want to assume what the
      # user intent is.
      assert "0..255" == inspect(@arity_type)
    end
  end
end
