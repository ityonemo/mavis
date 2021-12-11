defmodule TypeTest.RemoteString.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  describe "String.t" do
    test "is usable as any, basic types and self" do
      assert :ok = type(String.t()) ~> any()
      assert :ok = type(String.t()) ~> bitstring()
      assert :ok = type(String.t()) ~> binary()
      assert :ok = type(String.t()) ~> type(String.t())
    end

    test "is maybe usable as a bitstring with a wider unit" do
      assert {:maybe, _} = type(String.t()) ~> %Bitstring{unit: 16}
    end

    test "is maybe usable as a bitstring with a multiple of 8 fixed size part" do
      assert {:maybe, _} = type(String.t()) ~> %Bitstring{}
      assert {:maybe, _} = type(String.t()) ~> %Bitstring{size: 16}
      assert {:maybe, _} = type(String.t()) ~> %Bitstring{size: 16, unit: 8}
    end

    test "is maybe usable as a bitstring with units and sizes not multiple of 8" do
      assert {:maybe, _} = type(String.t()) ~> %Bitstring{size: 4, unit: 4}
      assert {:maybe, _} = type(String.t()) ~> %Bitstring{size: 3, unit: 5}
    end

    test "is not usable as a bitstring with unit factor of 8 and size not" do
      assert {:error, _} = type(String.t()) ~> %Bitstring{size: 3, unit: 4}
      assert {:error, _} = type(String.t()) ~> %Bitstring{size: 7, unit: 8}
      assert {:error, _} = type(String.t()) ~> %Bitstring{size: 13, unit: 16}

      # and also:
      assert {:error, _} = type(String.t()) ~> %Bitstring{size: 4, unit: 8}
    end
  end

  describe "empty bitstring" do
    test "is always usable as String.t" do
      assert :ok = %Bitstring{} ~> type(String.t())
    end
  end

  describe "bitstring types" do
    test "are maybe usable as String.t" do
      assert {:maybe, _} = binary() ~> type(String.t())
    end
  end
end
