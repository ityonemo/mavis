defmodule TypeTest.TypeBitstring.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Bitstring

  @empty_bitstring %Bitstring{size: 0, unit: 0}
  @basic_bitstring %Bitstring{size: 0, unit: 1}
  @basic_binary    %Bitstring{size: 0, unit: 8}

  describe "the intersection of empty bitstring" do
    test "with itself and any is itself" do
      assert @empty_bitstring == @empty_bitstring <~> any()
      assert @empty_bitstring == @empty_bitstring <~> @empty_bitstring
    end

    test "with any string with size 0 is itself" do
      assert @empty_bitstring == @empty_bitstring <~> @basic_bitstring
      assert @empty_bitstring == @empty_bitstring <~> @basic_binary
    end

    test "with a literal bitstring is the literal bitstring" do
      assert <<0::7>> == bitstring() <~> <<0::7>>
      assert "foo" == bitstring() <~> "foo"
      assert "foo" == binary() <~> "foo"
    end

    test "with any fixed size string is none" do
      assert none() == @empty_bitstring <~> %Bitstring{size: 8, unit: 0}
      assert none() == @empty_bitstring <~> %Bitstring{size: 8, unit: 8}
    end

    @tag :skip
    test "with all other types is none" do
      TypeTest.Targets.except([@empty_bitstring])
      |> Enum.each(fn target ->
        assert none() == @empty_bitstring <~> target
      end)
    end
  end

  describe "the intersection of basic bitstring" do
    test "with itself, integer and any is itself" do
      assert @basic_bitstring == @basic_bitstring <~> any()
      assert @basic_bitstring == @basic_bitstring <~> @basic_bitstring
    end

    test "with any string with size 1 is the more specific size" do
      assert @basic_binary                == @basic_bitstring <~> @basic_binary
      assert %Bitstring{size: 0, unit: 3} == @basic_bitstring <~> %Bitstring{size: 0, unit: 3}
    end

    test "with any fixed size string is the fixed size string" do
      assert %Bitstring{size: 8, unit: 0} == @basic_bitstring <~> %Bitstring{size: 8, unit: 0}
      assert %Bitstring{size: 8, unit: 8} == @basic_bitstring <~> %Bitstring{size: 8, unit: 8}
    end
  end

  describe "other combinations of bitstrings:" do
    test "disparate unit sizes" do
      assert %Bitstring{size: 0, unit: 24} == @basic_binary <~> %Bitstring{size: 0, unit: 3}
      assert %Bitstring{size: 0, unit: 24} == @basic_binary <~> %Bitstring{size: 0, unit: 6}
    end

    test "literals" do
      assert "foo" == %Bitstring{size: 24} <~> "foo"
      assert "foo" == %Bitstring{unit: 8} <~> "foo"

      assert "foo" == type(String.t()) <~> "foo"
      assert "foo" == type(String.t(3)) <~> "foo"
    end

    test "different offsets" do
      assert %Bitstring{size: 15, unit: 8} ==
        %Bitstring{size: 7, unit: 8} <~> %Bitstring{size: 15, unit: 8}
    end

    test "with unions" do
      assert @basic_binary == @basic_binary <~> (@basic_bitstring <|> atom())
      assert none() == @basic_binary <~> (atom() <|> port())
    end
  end

  test "regressions" do
    assert %Type.Bitstring{size: 16, unit: 8} =
      Type.intersect(
        %Type.Bitstring{size: 15, unit: 1},
        %Type.Bitstring{size: 0, unit: 8})

    assert %Type.Bitstring{size: 32, unit: 24} =
      Type.intersect(
        %Type.Bitstring{size: 14, unit: 6},
        %Type.Bitstring{size: 16, unit: 8})
  end
end
