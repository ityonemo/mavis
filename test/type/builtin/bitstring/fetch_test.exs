defmodule TypeTest.BuiltinBitstring.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Bitstring do
    @type bitstring_type :: bitstring
  end)

  describe "the bitstring/0 type" do
    test "is itself" do
      assert bitstring() == @bitstring_type
    end

    test "is what we expect" do
      assert %Type.Bitstring{size: 0, unit: 1} == @bitstring_type
    end
  end
end
