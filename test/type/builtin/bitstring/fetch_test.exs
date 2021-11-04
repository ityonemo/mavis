defmodule TypeTest.BuiltinBitstring.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the bitstring type" do
    pull_types(defmodule Bitstring do
      @type bitstring_type :: bitstring
    end)

    test "is itself" do
      assert bitstring() == @bitstring_type
    end

    test "matches to itself" do
      assert bitstring() = @bitstring_type
    end

    test "is what we expect" do
      assert %Type.Bitstring{size: 0, unit: 1} == @bitstring_type
    end
  end
end
