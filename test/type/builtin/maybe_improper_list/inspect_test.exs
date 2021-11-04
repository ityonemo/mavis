defmodule TypeTest.BuiltinMaybeImproperList.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the maybe_improper_list type" do
    pull_types(defmodule MaybeImproperList do
      @type maybe_improper_list_type :: maybe_improper_list
      @type maybe_improper_list_param_type :: maybe_improper_list(atom(), float())
    end)

    test "looks like a maybe_improper_list" do
      assert "maybe_improper_list()" == inspect(@maybe_improper_list_type)
    end

    test "code translates correctly" do
      assert @maybe_improper_list_type == eval_inspect(@maybe_improper_list_type)
    end

    test "with a parameter looks like a maybe_improper_list" do
      assert "maybe_improper_list(atom(), float())" == inspect(@maybe_improper_list_param_type)
    end

    test "with a parameter code translates correctly" do
      assert @maybe_improper_list_param_type == eval_type_str("maybe_improper_list(atom(), float())")
    end
  end
end
