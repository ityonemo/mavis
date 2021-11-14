defmodule TypeTest.BuiltinPort.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of port" do
    test "with any and port is itself" do
      assert port() == port() <~> any()
      assert port() == port() <~> port()
    end

    test "with none is none" do
      assert none() == port() <~> none()
    end

    test "with all other types is none" do
      [port()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == port() <~> target
      end)
    end
  end
end
