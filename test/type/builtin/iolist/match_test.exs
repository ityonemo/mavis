defmodule TypeTest.BuiltinIolist.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the iolist/0 type" do
    @iolist_type %Type{module: nil, name: :iolist, params: []}

    test "matches with itself" do
      assert iolist() = @iolist_type
    end
  end
end
