defmodule TypeTest.Remote.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Bitstring

  @empty_bitstring %Bitstring{}

  describe "the intersection of String.t" do
    test "with itself and any is itself" do
      assert remote(String.t()) == remote(String.t()) <~> remote(String.t())
      assert remote(String.t()) == builtin(:any) <~> remote(String.t())
    end

    test "with empty bitstring is empty bitstring" do
      assert @empty_bitstring == remote(String.t()) <~> @empty_bitstring
      assert @empty_bitstring == @empty_bitstring <~> remote(String.t())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([@empty_bitstring])
      |> Enum.each(fn target ->
        assert builtin(:none) == remote(String.t()) <~> target
      end)
    end
  end

  describe "the intersection of String.t/1" do
    test "with itself, string, and any is itself" do
      assert remote(String.t(3)) == remote(String.t(3)) <~> remote(String.t(3))
      assert remote(String.t(3)) == remote(String.t(3)) <~> remote(String.t)
      assert remote(String.t(3)) == builtin(:any) <~> remote(String.t(3))
    end

    test "with correctly sized bitstring is itself" do
      assert remote(String.t(3)) == remote(String.t(3)) <~> %Bitstring{size: 24}
    end

    test "with empty bitstring is nothing" do
      assert builtin(:none) == remote(String.t(3)) <~> @empty_bitstring
      assert builtin(:none) == @empty_bitstring <~> remote(String.t(3))
    end

    test "with wrongly sized string is nothing" do
      assert builtin(:none) == remote(String.t(3)) <~> remote(String.t(4))
    end
  end
end
