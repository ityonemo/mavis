defmodule TypeTest.BuiltinPid.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the pid/0 type" do
    @pid_type %Type{module: nil, name: :pid, params: []}

    test "matches with itself" do
      assert pid() = @pid_type
    end
  end
end
