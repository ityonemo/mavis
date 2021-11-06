defmodule TypeTest.BuiltinIodata.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :fetch

  describe "the iodata/0 type" do
    @iodata_type %Type.Union{
      of: [binary(), iolist()]}

    test "matches with itself" do
      assert iodata() = @iodata_type
    end
  end
end
