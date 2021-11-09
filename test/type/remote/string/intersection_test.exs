defmodule TypeTest.RemoteString.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Bitstring

  @empty_bitstring %Bitstring{}

  describe "the intersection of String.t" do
    test "with itself and any is itself" do
      assert type(String.t()) == type(String.t()) <~> type(String.t())
      assert type(String.t()) == any() <~> type(String.t())
    end

    test "with empty bitstring is empty bitstring" do
      assert @empty_bitstring == type(String.t()) <~> @empty_bitstring
      assert @empty_bitstring == @empty_bitstring <~> type(String.t())
    end

    test "with the literal bitstring is literal bitstring" do
      assert "" == type(String.t()) <~> ""
      assert "" == "" <~> type(String.t())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([@empty_bitstring, "foo"])
      |> Enum.each(fn target ->
        assert none() == type(String.t()) <~> target
      end)
    end
  end

  describe "the intersection of String.t/1" do
    test "with itself, string, and any is itself" do
      assert type(String.t(3)) == type(String.t(3)) <~> type(String.t(3))
      assert type(String.t(3)) == type(String.t(3)) <~> type(String.t)
      assert type(String.t(3)) == any() <~> type(String.t(3))
    end

    test "with correctly sized bitstring is itself" do
      assert type(String.t(3)) == type(String.t(3)) <~> %Bitstring{size: 24}
    end

    test "with empty bitstring is nothing" do
      assert none() == type(String.t(3)) <~> @empty_bitstring
      assert none() == @empty_bitstring <~> type(String.t(3))
    end

    test "with wrongly sized string is nothing" do
      assert none() == type(String.t(3)) <~> type(String.t(4))
    end
  end
end
