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
      assert iolist() == any() <~> iolist()

      assert iolist() == iolist() <~> iolist()
    end

    test "intersects with empty list" do
      assert [] == iolist() <~> []
      assert [] == [] <~> iolist()
    end

    test "intersects with a byte list" do
      assert list(byte()) == iolist() <~> list(byte())
      assert list(byte()) == list(byte()) <~> iolist()
    end

    test "intersects with a binary list" do
      assert list(binary()) == iolist() <~> list(binary())
      assert list(binary()) == list(binary()) <~> iolist()
    end

    test "acts as if it is a maybe_empty list" do
      nonempty = list(binary(), ...)
      assert nonempty == iolist() <~> nonempty
      assert nonempty == nonempty <~> iolist()
    end

    test "acts as if it can have a final of binary" do
      binfinal = %List{type: binary(), final: binary()}
      assert binfinal == iolist() <~> binfinal
      assert binfinal == binfinal <~> iolist()
    end

    test "intersects to arbitrary depth" do
      two_in = list(list(binary()))
      assert two_in == iolist() <~> two_in
      assert two_in == two_in <~> iolist()

      three_in = list(list(list(binary())))
      assert three_in == iolist() <~> three_in
      assert three_in == three_in <~> iolist()
    end

    test "if the list is different, there is only an empty list intersection" do
      assert [] == iolist() <~> list(atom())
      assert none() == iolist() <~> list(atom(), ...)
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