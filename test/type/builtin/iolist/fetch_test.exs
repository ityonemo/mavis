defmodule TypeTest.BuiltinIolist.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the iolist type" do
    pull_types(defmodule Iolist do
      @type iolist_type :: iolist
    end)

    test "is itself" do
      assert iolist() == @iolist_type
    end

    test "matches to itself" do
      assert iolist() = @iolist_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :iolist, params: []} == @iolist_type
    end
  end
end
