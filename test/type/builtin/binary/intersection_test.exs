defmodule TypeTest.BuiltinBinary.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of binary" do
    test "with any, bitstring, and binary is itself" do
      assert binary() == binary() <~> any()
      assert binary() == binary() <~> bitstring()
      assert binary() == binary() <~> binary()
    end

    test "with String.t is String.t" do
      assert type(String.t()) == binary() <~> type(String.t())
    end

    test "with a wider binary is the wider binary" do
      assert type(<<_::_*16>>) == binary() <~> type(<<_::_*16>>)
    end

    test "with a prefixed binary is the prefixed binary" do
      assert type(<<_::16>>) == binary() <~> type(<<_::16>>)
      assert type(<<_::8, _::_*8>>) == binary() <~> type(<<_::8, _::_*8>>)
    end

    test "with a non-binary binary is non-binary" do
      assert none() == binary() <~> type(<<_::4, _::_*8>>)
    end

    test "with a literal binary is the literal binary" do
      assert "foo" == binary() <~> "foo"
    end

    test "with a non-binary bitstring is none" do
      assert none() == binary() <~> <<3::3>>
    end

    test "with none is none" do
      assert none() == binary() <~> none()
    end

    test "with all other types is none" do
      [binary(), "foo", type(<<>>)]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == binary() <~> target
      end)
    end
  end
end
