defmodule TypeTest.Remote.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Bitstring

  @empty_bitstring %Bitstring{size: 0, unit: 0}

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
end
