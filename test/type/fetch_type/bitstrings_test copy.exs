defmodule TypeTest.Type.FetchType.BitstringsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  @moduletag :fetch

  alias Type.Bitstring

  @source TypeTest.TypeExample.Bitstrings

  test "empty bitstring literal" do
    assert {:ok, %Bitstring{size: 0, unit: 0}} == Type.fetch_type(@source, :empty_bitstring)
  end

  test "sized bitstring literal" do
    assert {:ok, %Bitstring{size: 47, unit: 0}} == Type.fetch_type(@source, :size_bitstring)
  end

  test "unit bitstring literal" do
    assert {:ok, %Bitstring{size: 0, unit: 16}} == Type.fetch_type(@source, :unit_bitstring)
  end

  test "unit and sized bitstring literal" do
    assert {:ok, %Bitstring{size: 12, unit: 8}} == Type.fetch_type(@source, :size_unit_bitstring)
  end

  test "bitstring/0" do
    assert {:ok, %Bitstring{size: 0, unit: 1}} == Type.fetch_type(@source, :bitstring_type)
  end

  test "binary/0" do
    assert {:ok, %Bitstring{size: 0, unit: 8}} == Type.fetch_type(@source, :binary_type)
  end

  test "iodata/0" do
    assert {:ok, (%Bitstring{size: 0, unit: 8} <|> builtin(:iolist))} == Type.fetch_type(@source, :iodata_type)
  end

  test "iolist/0" do
    assert {:ok, builtin(:iolist)} == Type.fetch_type(@source, :iolist_type)
  end
end
