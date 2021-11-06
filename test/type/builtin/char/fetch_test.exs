defmodule TypeTest.BuiltinChar.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Char do
    @type char_type :: char
  end)

  describe "the char/0 type" do
    test "is itself" do
      assert char() == @char_type
    end

    test "is what we expect" do
      assert 0..0x10_FFFF == @char_type
    end
  end
end
