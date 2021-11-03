defmodule TypeTest.BuiltinMfa.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the mfa type" do
    pull_types(defmodule Mfa do
      @type mfa_type :: mfa
    end)

    test "looks like a mfa" do
      assert "mfa()" == inspect(@mfa_type)
    end

    test "code translates correctly" do
      assert @mfa_type == eval_inspect(@mfa_type)
    end
  end
end
