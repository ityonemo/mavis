defmodule TypeTest.Tuple.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase
  @moduletag :inspect

  pull_types(defmodule Tuple do
    @type empty_tuple :: {}
    @type normal_tuple :: {:ok, atom}
  end)

  describe "the empty tuple type" do
    test "looks as it should" do
      assert "type({})" == inspect(@empty_tuple)
    end

    test "code translates correctly" do
      assert @empty_tuple == eval_inspect(@empty_tuple)
    end
  end

  describe "the general tuple type" do
    test "looks as it should" do
      assert "type({:ok, atom()})" == inspect(@normal_tuple)
    end

    test "code translates correctly" do
      assert @normal_tuple == eval_inspect(@normal_tuple)
    end
  end
end
