defmodule TypeTest.TypeIolist.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection
  @moduletag :skip # due to union issues

  import Type, only: :macros

  alias Type.{Bitstring, List}

  describe "iolist" do
    test "intersects with any, and self" do
      assert iolist() == iolist() <~> any()
      assert iolist() == iolist() <~> iolist()
    end

    test "intersects with empty list" do
      assert [] == iolist() <~> []
    end

    test "intersects with a byte list" do
      assert list(byte()) == iolist() <~> list(byte())
    end

    test "intersects with a binary list" do
      assert list(binary()) == iolist() <~> list(binary())
    end

    test "acts as if it is a maybe_empty list" do
      assert nonempty_list(binary()) == iolist() <~> nonempty_list(binary())
    end

    test "acts as if it can have a final of binary" do
      assert %List{type: binary(), final: binary()} == iolist() <~> %List{type: binary(), final: binary()}
    end

    test "intersects to arbitrary depth" do
      two_in = list(list(binary()))
      assert two_in == iolist() <~> two_in

      three_in = list(list(list(binary())))
      assert three_in == iolist() <~> three_in
    end

    test "if the list is different, there is only an empty list intersection" do
      assert [] == iolist() <~> list(atom())
      assert none() == iolist() <~> nonempty_list(atom())
    end

    test "with real examples is the same" do
      assert "foo" == iodata() <~> "foo"
      assert ["foo", "bar"] == iodata() <~> ["foo", "bar"]
      assert ["foo", 47] == iodata() <~> ["foo", 47]
      assert ["foo", [47]] == iodata() <~> ["foo", [47]]
      assert ["foo" | "bar"] == iodata() <~> ["foo" | "bar"]
    end

    test "if the final is different, there's no interesction" do
      assert none() == iolist() <~> %List{type: atom(), final: atom()}
    end

    @tag :skip # due to function crashes
    test "intersects with nothing else" do
      TypeTest.Targets.except([[], list(), ["foo", "bar"]])
      |> Enum.each(fn target ->
        assert none() == iolist() <~> target
      end)
    end
  end
end
