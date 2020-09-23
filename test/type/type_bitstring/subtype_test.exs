defmodule TypeTest.TypeBitstring.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Bitstring

  @empty_bitstring %Bitstring{size: 0, unit: 0}
  @basic_bitstring %Bitstring{size: 0, unit: 1}
  @basic_binary    %Bitstring{size: 0, unit: 8}

  describe "the empty bitstring" do
    test "is a subtype of itself and any" do
      assert @empty_bitstring in @empty_bitstring
      assert @empty_bitstring in builtin(:any)
    end

    test "is a subtype of any bitstring with size 0" do
      assert @empty_bitstring in @basic_bitstring
      assert @empty_bitstring in @basic_binary
    end

    test "is not a subtype of any bitstring that has size" do
      refute @empty_bitstring in %Bitstring{size: 1, unit: 0}
      refute @empty_bitstring in %Bitstring{size: 1, unit: 1}
      refute @empty_bitstring in %Bitstring{size: 8, unit: 8}
    end
  end

  describe "the basic binary" do
    test "is a subtype of itself, basic bitstring, and more granular bitstrings" do
      assert @basic_binary in @basic_binary
      assert @basic_binary in @basic_bitstring
      assert @basic_binary in %Bitstring{size: 0, unit: 4}
    end
  end

  describe "a binary with a size" do
    test "is a subtype of basic binary, and basic bitstring" do
      assert %Bitstring{size: 64, unit: 0} in @basic_binary ## <- binary constant
      assert %Bitstring{size: 32, unit: 8} in @basic_binary

      assert %Bitstring{size: 7, unit: 3} in @basic_bitstring ## <- YOLO
    end

    test "is not a subtype when there is a strange size" do
      refute %Bitstring{size: 31, unit: 0} in @basic_binary
      refute %Bitstring{size: 4, unit: 8} in @basic_binary
    end
  end

end
