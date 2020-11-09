defmodule TypeTest.TypeIolist.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.{Bitstring, List}

  @any builtin(:any)
  @char 0..0x10FFFF
  @binary %Bitstring{size: 0, unit: 8}

  describe "iolist" do
    test "intersects with any, and self" do
      assert builtin(:iolist) == builtin(:iolist) <~> @any
      assert builtin(:iolist) == @any <~> builtin(:iolist)

      assert builtin(:iolist) == builtin(:iolist) <~> builtin(:iolist)
    end

    test "intersects with empty list" do
      assert [] == builtin(:iolist) <~> []
      assert [] == [] <~> builtin(:iolist)
    end

    test "intersects with a charlist" do
      assert %List{type: @char} == builtin(:iolist) <~> %List{type: @char}
      assert %List{type: @char} == %List{type: @char} <~> builtin(:iolist)
    end

    test "intersects with a binary list" do
      assert %List{type: @binary} == builtin(:iolist) <~> %List{type: @binary}
      assert %List{type: @binary} == %List{type: @binary} <~> builtin(:iolist)
    end

    test "acts as if it is a maybe_empty list" do
      nonempty = %List{type: @binary, nonempty: true}
      assert nonempty == builtin(:iolist) <~> nonempty
      assert nonempty = nonempty <~> builtin(:iolist)
    end

    test "acts as if it can have a final of binary" do
      binfinal = %List{type: @binary, final: @binary}
      assert binfinal == builtin(:iolist) <~> binfinal
      assert binfinal = binfinal <~> builtin(:iolist)
    end

    test "intersects to arbitrary depth" do
      two_in = %List{type: %List{type: @binary}}
      assert two_in == builtin(:iolist) <~> two_in
      assert two_in == two_in <~> builtin(:iolist)

      three_in = %List{type: %List{type: %List{type: @binary}}}
      assert three_in == builtin(:iolist) <~> three_in
      assert three_in == three_in <~> builtin(:iolist)
    end

    test "if the list is different, there's no intersection" do
      assert builtin(:none) == builtin(:iolist) <~> %List{type: builtin(:atom)}
    end

    test "if the final is different, there's no interesction" do
      assert builtin(:none) == builtin(:iolist) <~> %List{final: builtin(:atom)}
    end

    test "intersects with nothing else" do
      TypeTest.Targets.except([[], %List{}])
      |> Enum.each(fn target ->
        assert builtin(:none) == builtin(:iolist) <~> target
      end)
    end
  end
end
