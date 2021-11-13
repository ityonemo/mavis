defmodule TypeTest.BuiltinIodata.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of iodata" do
    test "with any and iodata is itself" do
      assert iodata() == iodata() <~> any()
      assert iodata() == iodata() <~> iodata()
    end

    test "with iolist or binary is the subtype" do
      assert iolist() == iodata() <~> iolist()
      assert binary() == binary() <~> iodata()
    end

    test "with real examples is the same" do
      assert "foo" == iodata() <~> "foo"
      assert ["foo", "bar"] == iodata() <~> ["foo", "bar"]
      assert ["foo", 47] == iodata() <~> ["foo", 47]
      assert ["foo", [47]] == iodata() <~> ["foo", [47]]
      assert ["foo" | "bar"] == iodata() <~> ["foo" | "bar"]
    end

    test "with none is none" do
      assert none() == iodata() <~> none()
    end

    test "with all other types is none" do
      [[], ["foo", "bar"], list(), "foo", type(<<>>)]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == iodata() <~> target
      end)
    end
  end
end
