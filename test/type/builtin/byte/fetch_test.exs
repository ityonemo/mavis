defmodule TypeTest.BuiltinByte.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Byte do
    @type byte_type :: byte
  end)

  describe "the byte/0 type" do
    test "is itself" do
      assert byte() == @byte_type
    end

    test "is what we expect" do
      assert 0..255 == @byte_type
    end
  end
end
