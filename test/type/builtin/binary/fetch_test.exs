defmodule TypeTest.BuiltinBinary.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Binary do
    @type binary_type :: binary
  end)

  describe "the binary/0 type" do
    test "is itself" do
      assert binary() == @binary_type
    end

    test "is what we expect" do
      assert %Type.Bitstring{size: 0, unit: 8} == @binary_type
    end
  end
end
