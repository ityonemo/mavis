defmodule TypeTest.Remote.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  @empty_bitstring %Bitstring{size: 0, unit: 0}
  @basic_bitstring %Bitstring{size: 0, unit: 1}
  @basic_binary %Bitstring{size: 0, unit: 8}

  describe "String.t" do
    test "is usable as any, basic types and self" do
      assert :ok = remote(String.t()) ~> builtin(:any)
      assert :ok = remote(String.t()) ~> @basic_bitstring
      assert :ok = remote(String.t()) ~> @basic_binary
      assert :ok = remote(String.t()) ~> remote(String.t())
    end

    test "is maybe usable as a bitstring with a wider unit" do
      assert {:maybe, _} = remote(String.t()) ~> %Bitstring{size: 0, unit: 16}
    end

    test "is maybe usable as a bitstring with a multiple of 8 fixed size part" do
      assert {:maybe, _} = remote(String.t()) ~> @empty_bitstring
      assert {:maybe, _} = remote(String.t()) ~> %Bitstring{size: 16, unit: 0}
      assert {:maybe, _} = remote(String.t()) ~> %Bitstring{size: 16, unit: 8}
    end

    test "is maybe usable as a bitstring with units and sizes not multiple of 8" do
      assert {:maybe, _} = remote(String.t()) ~> %Bitstring{size: 4, unit: 4}
      assert {:maybe, _} = remote(String.t()) ~> %Bitstring{size: 3, unit: 5}
    end

    test "is not usable as a bitstring with unit factor of 8 and size not" do
      assert {:error, _} = remote(String.t()) ~> %Bitstring{size: 3, unit: 4}
      assert {:error, _} = remote(String.t()) ~> %Bitstring{size: 7, unit: 8}
      assert {:error, _} = remote(String.t()) ~> %Bitstring{size: 13, unit: 16}

      # and also:
      assert {:error, _} = remote(String.t()) ~> %Bitstring{size: 4, unit: 8}
    end
  end

  describe "empty bitstring" do
    test "is always usable as String.t" do
      assert :ok = @empty_bitstring ~> remote(String.t())
    end
  end

  describe "bitstring types" do
    test "are maybe usable as String.t" do
      assert {:maybe, [msg]} = @basic_binary ~> remote(String.t())
      assert msg.meta[:message] =~ "remote encapsulation"
    end
  end
end
