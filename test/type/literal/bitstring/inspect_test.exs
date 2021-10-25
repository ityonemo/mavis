defmodule TypeTest.LiteralBitstring.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  describe "the literal bitstring type" do
    @literal_bitstring Type.of(<<7::3>>)

    test "looks like a bitstring" do
      assert "<<7::size(3)>>" == inspect(@literal_bitstring)
    end

    test "code translates correctly" do
      assert <<7::3>> == eval_inspect(@literal_bitstring)
    end
  end

  describe "the literal binary type" do
    @literal_bitstring Type.of("foobar")

    test "looks like a bitstring" do
      assert ~s("foobar") == inspect(@literal_bitstring)
    end

    test "code translates correctly" do
      assert "foobar" == eval_inspect(@literal_bitstring)
    end
  end
end
