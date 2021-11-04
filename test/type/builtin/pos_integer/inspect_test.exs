defmodule TypeTest.BuiltinPosInteger.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the pos_integer type" do
    pull_types(defmodule PosInteger do
      @type pos_integer_type :: pos_integer()
    end)

    test "is presented as itself" do
      assert "pos_integer()" == inspect(@pos_integer_type)
    end

    test "code translates correctly" do
      assert @pos_integer_type == eval_inspect(@pos_integer_type)
    end
  end
end
