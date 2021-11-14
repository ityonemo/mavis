defmodule TypeTest.BuiltinMfa.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of mfa" do
    test "with any, tuple, and mfa is itself" do
      assert mfa() == mfa() <~> any()
      assert mfa() == mfa() <~> tuple()
      assert mfa() == mfa() <~> mfa()
    end

    test "with none is none" do
      assert none() == mfa() <~> none()
    end

    test "with all other types is none" do
      []
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == mfa() <~> target
      end)
    end
  end
end
