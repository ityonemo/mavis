defmodule TypeTest.BuiltinIodata.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Iodata do
    @type iodata_type :: iodata
  end)

  describe "the iodata/0 type" do
    test "is itself" do
      assert iodata() == @iodata_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [binary(), iolist()]} == @iodata_type
    end
  end
end
