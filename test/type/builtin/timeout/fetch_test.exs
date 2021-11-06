defmodule TypeTest.BuiltinTimeout.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Timeout do
    @type timeout_type :: timeout()
  end)

  describe "the timeout/0 type" do
    test "is itself" do
      assert timeout() == @timeout_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [:infinity, pos_integer(), 0]} == @timeout_type
    end
  end
end
