defmodule TypeTest.Remote.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "String.t" do
    test "is usable as any, basic types and self" do
      assert :ok = remote(String.t()) ~> any()
      assert :ok = remote(String.t()) ~> bitstring()
      assert :ok = remote(String.t()) ~> binary()
      assert :ok = remote(String.t()) ~> remote(String.t())
    end

    test "is maybe usable as a bitstring with a wider unit" do
      assert {:maybe, _} = remote(String.t()) ~> %Bitstring{unit: 16}
    end

    test "is maybe usable as a bitstring with a multiple of 8 fixed size part" do
      assert {:maybe, _} = remote(String.t()) ~> %Bitstring{}
      assert {:maybe, _} = remote(String.t()) ~> %Bitstring{size: 16}
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

  describe "String.t/1" do
    test "is usable as any, basic types and self" do
      assert :ok = remote(String.t(3)) ~> any()
      assert :ok = remote(String.t(3)) ~> bitstring()
      assert :ok = remote(String.t(3)) ~> binary()
      assert :ok = remote(String.t(3)) ~> remote(String.t())
      assert :ok = remote(String.t(3)) ~> remote(String.t(3))
    end

    test "is usable as a bitstring with the correct size parameters" do
      assert :ok = remote(String.t(3)) ~> %Bitstring{size: 24}
      assert :ok = remote(String.t(3)) ~> %Bitstring{unit: 24}
      assert :ok = remote(String.t(3)) ~> %Bitstring{size: 8, unit: 8}
    end

    test "is not usable as a bitstring with the incorrect correct size parameters" do
      assert {:error, _} = remote(String.t(3)) ~> %Bitstring{size: 16}
      assert {:error, _} = remote(String.t(3)) ~> %Bitstring{unit: 7}
      assert {:error, _} = remote(String.t(3)) ~> %Bitstring{size: 8, unit: 5}
    end
  end

  describe "empty bitstring" do
    test "is always usable as String.t" do
      assert :ok = %Bitstring{} ~> remote(String.t())
      assert :ok = %Bitstring{} ~> remote(String.t(0))
    end
  end

  describe "bitstring types" do
    test "are maybe usable as String.t" do
      assert {:maybe, [msg]} = binary() ~> remote(String.t())
      assert msg.meta[:message] =~ "remote encapsulation"
    end

    test "are maybe usable as the equivalent String.t/1" do
      assert {:maybe, _} = %Bitstring{unit: 8} ~> remote(String.t(3))
      assert {:maybe, _} = %Bitstring{size: 24} ~> remote(String.t(3))
    end

    test "are not usable as the equivalent String.t/1" do
      assert {:error, _} = %Bitstring{size: 8} ~> remote(String.t(3))
      assert {:error, _} = %Bitstring{unit: 7} ~> remote(String.t(3))
      assert {:error, _} = %Bitstring{unit: 5, size: 8} ~> remote(String.t(3))
    end
  end
end
