defmodule TypeTest.BuiltinPid.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the pid type" do
    pull_types(defmodule Pid do
      @type pid_type :: pid()
    end)

    test "is presented as itself" do
      assert "pid()" == inspect(@pid_type)
    end

    test "code translates correctly" do
      assert @pid_type == eval_inspect(@pid_type)
    end
  end
end
