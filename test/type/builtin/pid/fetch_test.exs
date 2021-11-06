defmodule TypeTest.BuiltinPid.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Pid do
    @type pid_type :: pid()
  end)

  describe "the pid/0 type" do
    test "is itself" do
      assert pid() == @pid_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :pid, params: []} == @pid_type
    end
  end
end
