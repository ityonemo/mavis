defmodule TypeTest.BuiltinIodata.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the iodata type" do
    pull_types(defmodule Iodata do
      @type iodata_type :: iodata
    end)

    test "is itself" do
      assert iodata() == @iodata_type
    end

    test "matches to itself" do
      assert iodata() = @iodata_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [
        %Type.Bitstring{size: 0, unit: 8},
        %Type{module: nil, name: :iolist, params: []},
      ]} == @iodata_type
    end
  end
end
