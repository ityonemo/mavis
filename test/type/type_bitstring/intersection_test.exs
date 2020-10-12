defmodule TypeTest.TypeBitstring.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  alias Type.Bitstring

  @empty_bitstring %Bitstring{size: 0, unit: 0}
  @basic_bitstring %Bitstring{size: 0, unit: 1}
  @basic_binary    %Bitstring{size: 0, unit: 8}

  describe "the intersection of empty bitstring" do
    test "with itself, integer and any is itself" do
      assert @empty_bitstring == Type.intersection(@empty_bitstring, builtin(:any))
      assert @empty_bitstring == Type.intersection(@empty_bitstring, @empty_bitstring)
    end

    test "with any string with size 0 is itself" do
      assert @empty_bitstring == Type.intersection(@empty_bitstring, @basic_bitstring)
      assert @empty_bitstring == Type.intersection(@empty_bitstring, @basic_binary)
    end

    test "with any fixed size string is none" do
      assert builtin(:none) == Type.intersection(@empty_bitstring, %Bitstring{size: 8, unit: 0})
      assert builtin(:none) == Type.intersection(@empty_bitstring, %Bitstring{size: 8, unit: 8})
    end

    test "with all other types is none" do
      TypeTest.Targets.except([@empty_bitstring])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(@empty_bitstring, target)
      end)
    end
  end

  describe "the intersection of basic bitstring" do
    test "with itself, integer and any is itself" do
      assert @basic_bitstring == Type.intersection(@basic_bitstring, builtin(:any))
      assert @basic_bitstring == Type.intersection(@basic_bitstring, @basic_bitstring)
    end

    test "with any string with size 1 is the more specific size" do
      assert @basic_binary                == Type.intersection(@basic_bitstring, @basic_binary)
      assert %Bitstring{size: 0, unit: 3} == Type.intersection(@basic_bitstring, %Bitstring{size: 0, unit: 3})
    end

    test "with any fixed size string is the fixed size string" do
      assert %Bitstring{size: 8, unit: 0} == Type.intersection(@basic_bitstring, %Bitstring{size: 8, unit: 0})
      assert %Bitstring{size: 8, unit: 8} == Type.intersection(@basic_bitstring, %Bitstring{size: 8, unit: 8})
    end
  end

  describe "other combinations" do
    test "disparate unit sizes" do
      assert %Bitstring{size: 0, unit: 24} == Type.intersection(@basic_binary, %Bitstring{size: 0, unit: 3})
      assert %Bitstring{size: 0, unit: 24} == Type.intersection(@basic_binary, %Bitstring{size: 0, unit: 6})
    end

    test "different offsets" do
      assert %Bitstring{size: 15, unit: 8} ==
        Type.intersection(%Bitstring{size: 7, unit: 8}, %Bitstring{size: 15, unit: 8})
    end

    test "with unions" do
      assert @basic_binary == Type.intersection(@basic_binary, (@basic_bitstring <|> builtin(:atom)))
      assert builtin(:none) == Type.intersection(@basic_binary, (builtin(:atom) <|> builtin(:port)))
    end
  end
end
