defmodule TypeTest.BuiltinBitstring.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of bitstring" do
    test "with any, bitstring, and bitstring is itself" do
      assert bitstring() == bitstring() <~> any()
      assert bitstring() == bitstring() <~> bitstring()
      assert bitstring() == bitstring() <~> bitstring()
    end

    test "with binary is binary" do
      assert binary() == bitstring() <~> binary()
    end

    test "with String.t is String.t" do
      assert type(String.t()) == bitstring() <~> type(String.t())
    end

    test "with a wider bitstring is the wider bitstring" do
      assert type(<<_::_*16>>) == bitstring() <~> type(<<_::_*16>>)
    end

    test "with a prefixed bitstring is the prefixed bitstring" do
      assert type(<<_::16>>) == bitstring() <~> type(<<_::16>>)
      assert type(<<_::8, _::_*8>>) == bitstring() <~> type(<<_::8, _::_*8>>)
    end

    test "with a literal bitstring is the literal bitstring" do
      assert "foo" == bitstring() <~> "foo"
      assert <<3::3>> == bitstring() <~> <<3::3>>
    end

    test "with none is none" do
      assert none() == bitstring() <~> none()
    end

    test "with all other types is none" do
      [bitstring(), "foo", type(<<>>), <<0::7>>]
      |> TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == bitstring() <~> target
      end)
    end
  end
end
