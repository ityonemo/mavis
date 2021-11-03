defmodule TypeTest.BuiltinMaybeImproperList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the maybe_improper_list type" do
    pull_types(defmodule MaybeImproperList do
      @type maybe_improper_list_type :: maybe_improper_list
    end)

    test "looks like a maybe_improper_list" do
      assert "maybe_improper_list()" == inspect(@maybe_improper_list_type)
    end

    test "code translates correctly" do
      assert @maybe_improper_list_type == eval_inspect(@maybe_improper_list_type)
    end
  end
end
