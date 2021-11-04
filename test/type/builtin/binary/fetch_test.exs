defmodule TypeTest.BuiltinBinary.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the binary type" do
    pull_types(defmodule Binary do
      @type binary_type :: binary
    end)

    test "is itself" do
      assert binary() == @binary_type
    end

    test "matches to itself" do
      assert binary() = @binary_type
    end

    test "is what we expect" do
      assert %Type.Bitstring{size: 0, unit: 8} == @binary_type
    end
  end
end
