defmodule TypeTest.BuiltinIdentifier.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of identifier" do
    test "with any and identifier is itself" do
      assert identifier() == identifier() <~> any()
      assert identifier() == identifier() <~> identifier()
    end

    test "with any identifier subtype is the subtype" do
      assert pid() == identifier() <~> pid()
      assert port() == identifier() <~> port()
      assert reference() == identifier() <~> reference()
    end

    test "with none is none" do
      assert none() == identifier() <~> none()
    end

    test "with all other types is none" do
      [pid(), port(), reference()]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == identifier() <~> target
      end)
    end
  end
end
