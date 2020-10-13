defmodule TypeTest.Type.FetchSpec.BitstringsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.SpecCase

  @moduletag :fetch

  alias Type.Bitstring

  @source TypeTest.SpecExample.Bitstrings

  test "empty bitstring literal" do
    assert {:ok, identity_for(%Bitstring{size: 0, unit: 0})} ==
      Type.fetch_spec(@source, :empty_bitstring_spec, 1)
  end

  test "sized bitstring literal" do
    assert {:ok, identity_for(%Bitstring{size: 47, unit: 0})} ==
      Type.fetch_spec(@source, :size_bitstring_spec, 1)
  end

  test "unit bitstring literal" do
    assert {:ok, identity_for(%Bitstring{size: 0, unit: 16})} ==
      Type.fetch_spec(@source, :unit_bitstring_spec, 1)
  end

  test "unit and sized bitstring literal" do
    assert {:ok, identity_for(%Bitstring{size: 12, unit: 8})} ==
      Type.fetch_spec(@source, :size_unit_bitstring_spec, 1)
  end

  test "bitstring/0" do
    assert {:ok, identity_for(%Bitstring{size: 0, unit: 1})} ==
      Type.fetch_spec(@source, :bitstring_spec, 1)
  end

  test "binary/0" do
    assert {:ok, identity_for(%Bitstring{size: 0, unit: 8})} ==
      Type.fetch_spec(@source, :binary_spec, 1)
  end

  test "iodata/0" do
    assert {:ok, identity_for(%Bitstring{size: 0, unit: 8} <|> builtin(:iolist))} ==
      Type.fetch_spec(@source, :iodata_spec, 1)
  end

  test "iolist/0" do
    assert {:ok, identity_for(builtin(:iolist))} ==
      Type.fetch_spec(@source, :iolist_spec, 1)
  end
end
