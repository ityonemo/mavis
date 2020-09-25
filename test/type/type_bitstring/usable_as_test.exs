defmodule TypeTest.TypeBitString.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.{Bitstring, Message}

  @empty_bitstring %Bitstring{size: 0, unit: 0}
  @basic_bitstring %Bitstring{size: 0, unit: 1}
  @basic_binary %Bitstring{size: 0, unit: 8}

  test "all bitstring types are usable as any and self" do
    assert :ok = @empty_bitstring ~> builtin(:any)
    assert :ok = @basic_bitstring ~> builtin(:any)
    assert :ok = @basic_binary ~> builtin(:any)
    assert :ok = %Bitstring{size: 3, unit: 4} ~> builtin(:any)

    assert :ok = @empty_bitstring ~> @empty_bitstring
    assert :ok = @basic_bitstring ~> @basic_bitstring
    assert :ok = @basic_binary ~> @basic_binary
    assert :ok = %Bitstring{size: 3, unit: 4} ~> %Bitstring{size: 3, unit: 4}
  end

  describe "the empty bitstring type" do
    test "is usable as any zero size bitstring" do
      assert :ok == @empty_bitstring ~> @basic_bitstring
      assert :ok == @empty_bitstring ~> @basic_binary
    end

    test "is not usable as a nonzero size bitstring" do
      nonzero_bitstring = %Bitstring{size: 1, unit: 4}
      assert {:error, %Message{type: @empty_bitstring, target: ^nonzero_bitstring}} =
        @empty_bitstring ~> nonzero_bitstring
    end
  end

  describe "fixed length bitstrings" do
    test "are usable as themselves" do
      assert :ok = %Bitstring{size: 16, unit: 0} ~> %Bitstring{size: 16, unit: 0}
    end

    test "are not usable as other fixed-length bitstrings" do
      char2 = %Bitstring{size: 16, unit: 0}
      char1 = %Bitstring{size: 8, unit: 0}
      assert {:error, %Message{type: ^char2, target: ^char1}} = char2 ~> char1
    end
  end

  describe "the basic bitstring type" do
    test "is maybe usable as all other bitstrings" do
      assert {:maybe, [%Message{type: @basic_bitstring, target: @empty_bitstring}]} =
        @basic_bitstring ~> @empty_bitstring

      assert {:maybe, [%Message{type: @basic_bitstring, target: @basic_binary}]} =
        @basic_bitstring ~> @basic_binary

      assert {:maybe, [%Message{type: @basic_bitstring, target: %Bitstring{size: 7, unit: 2}}]} =
        @basic_bitstring ~> %Bitstring{size: 7, unit: 2}

      assert {:maybe, [%Message{type: @basic_bitstring, target: %Bitstring{size: 3, unit: 1}}]} =
        @basic_bitstring ~> %Bitstring{size: 3, unit: 1}
    end
  end

  describe "for the basic binary type" do
    test "is usable as a bitstring or unit that is a factor" do
      assert :ok = @basic_binary ~> @basic_bitstring
      assert :ok = @basic_binary ~> %Bitstring{size: 0, unit: 4}
    end

    test "is maybe usable as some things" do
      # not known if there are enough multiples to get there.
      assert {:maybe, [%Message{type: @basic_binary, target: %Bitstring{size: 8, unit: 0}}]} =
        @basic_binary ~> %Bitstring{size: 8, unit: 0}
      # competely strange factors that sometimes multiple to 8
      assert {:maybe, [%Message{type: @basic_binary, target: %Bitstring{size: 3, unit: 5}}]} =
        @basic_binary ~> %Bitstring{size: 3, unit: 5}
    end

    test "is never usable as something which can never be a non-multiple-of-8" do
      assert {:error, %Message{type: @basic_binary, target: %Bitstring{size: 3, unit: 4}}} =
        @basic_binary ~> %Bitstring{size: 3, unit: 4}
    end
  end

  describe "corner cases:" do
    test "non-power-of-two" do
      bs_1 = %Bitstring{size: 13, unit: 3}
      bs_2 = %Bitstring{size: 7, unit: 9}

      assert {:maybe, [%Message{type: ^bs_1, target: ^bs_2}]} = bs_1 ~> bs_2
    end

    test "same unit, different sizes." do
      bs_1 = %Bitstring{size: 22, unit: 3}
      bs_2 = %Bitstring{size: 16, unit: 3}

      assert :ok = bs_1 ~> bs_2
    end

    test "random values" do
      bs_1 = %Bitstring{size: 5, unit: 7}
      bs_2 = %Bitstring{size: 9, unit: 2}

      assert {:maybe, [%Message{type: ^bs_1, target: ^bs_2}]} = bs_1 ~> bs_2
    end
  end

  test "bitstrings are usable as unions including their supertype" do
    assert :ok = %Bitstring{size: 16, unit: 8} ~> (%Bitstring{size: 0, unit: 8} | builtin(:atom))
  end

  test "bitstrings are not usable as disjoint unions" do
    assert {:error, _} = %Bitstring{size: 16, unit: 8} ~> (builtin(:pid) | builtin(:atom))
  end

  test "bitstrings generally are not usable as other types" do
    targets = TypeTest.Targets.except([@empty_bitstring])
    Enum.each(targets, fn target ->
      assert {:error, %Message{type: @empty_bitstring, target: ^target}} =
        (@empty_bitstring ~> target)
    end)

    Enum.each(targets, fn target ->
      assert {:error, %Message{type: @basic_binary, target: ^target}} =
        (@basic_binary ~> target)
    end)

    Enum.each(targets, fn target ->
      assert {:error, %Message{type: @basic_bitstring, target: ^target}} =
        (@basic_bitstring ~> target)
    end)
  end
end
