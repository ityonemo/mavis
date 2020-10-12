defmodule TypeTest.Type.Inspect.BitstringsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.InspectCase

  @moduletag :inspect

  alias Type.Bitstring

  @source TypeTest.TypeExample.Bitstrings

  test "empty bitstring literal" do
    assert "<<>>" == inspect_type(@source, :empty_bitstring)
  end

  @type empty_bitstring :: <<>>
  @type size_bitstring :: <<_::47>>
  @type unit_bitstring :: <<_::_*8>>
  @type size_unit_bitstring :: <<_::12, _::_*8>>

  test "sized bitstring literal" do
    assert "<<_::47>>" == inspect_type(@source, :size_bitstring)
  end

  test "unit bitstring literal" do
    assert "<<_::_*16>>" == inspect_type(@source, :unit_bitstring)
  end

  test "unit and sized bitstring literal" do
    assert "<<_::12, _::_*8>>" == inspect_type(@source, :size_unit_bitstring)
  end

  test "bitstring/0" do
    assert "bitstring()" == inspect_type(@source, :bitstring_type)
  end

  test "binary/0" do
    assert "binary()" == inspect_type(@source, :binary_type)
  end

  test "iodata/0" do
    assert "iodata()" == inspect_type(@source, :iodata_type)
  end

  test "iolist/0" do
    assert "iolist()" == inspect_type(@source, :iolist_type)
  end
end
