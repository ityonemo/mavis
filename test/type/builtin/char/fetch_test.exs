defmodule TypeTest.BuiltinChar.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the char type" do
    pull_types(defmodule Char do
      @type char_type :: char
    end)

    test "is itself" do
      assert char() == @char_type
    end

    test "matches to itself" do
      assert char() = @char_type
    end

    test "is what we expect" do
      assert 0..0x10_FFFF == @char_type
    end
  end
end
