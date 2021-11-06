defmodule TypeTest.BuiltinTuple.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Tuple do
    @type tuple_type :: tuple()
  end)

  describe "the tuple/0 type" do
    test "is itself" do
      assert tuple() == @tuple_type
    end

    test "is what we expect" do
      assert %Type.Tuple{elements: [], fixed: false} == @tuple_type
    end
  end
end
