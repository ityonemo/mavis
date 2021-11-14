defmodule TypeTest.BuiltinPid.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of pid" do
    test "with any and pid is itself" do
      assert pid() == pid() <~> any()
      assert pid() == pid() <~> pid()
    end

    test "with none is none" do
      assert none() == pid() <~> none()
    end

    test "with all other types is none" do
      [pid()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == pid() <~> target
      end)
    end
  end
end
