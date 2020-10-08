defmodule TypeTest.Type.FetchType.NumbersTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  @moduletag :fetch

  @source TypeTest.TypeExample.Numbers

  test "literal integers" do
    assert 47 == Type.fetch_type(@source, :literal_int)
    assert -47 == Type.fetch_type(@source, :literal_neg_int)
  end

  test "ranges" do
    assert 7..47 == Type.fetch_type(@source, :range)
    assert -47..-7 == Type.fetch_type(@source, :neg_range)
  end

  test "builtin float" do
    assert builtin(:float) == Type.fetch_type(@source, :float_type)
  end

  test "builtin integers" do
    assert builtin(:integer) == Type.fetch_type(@source, :integer_type)
    assert builtin(:neg_integer) == Type.fetch_type(@source, :neg_integer_type)
    assert builtin(:non_neg_integer) == Type.fetch_type(@source, :non_neg_integer_type)
    assert builtin(:pos_integer) == Type.fetch_type(@source, :pos_integer_type)
  end

  test "special classes of integers" do
    assert 0..255 == Type.fetch_type(@source, :arity_type)
    assert 0..255 == Type.fetch_type(@source, :byte_type)
    assert 0..0x10FFFF == Type.fetch_type(@source, :char_type)
  end

  test "number" do
    assert (builtin(:float) | builtin(:integer)) == Type.fetch_type(@source, :number_type)
  end

  test "timeout" do
    assert (builtin(:non_neg_integer) | :infinity) == Type.fetch_type(@source, :timeout_type)
  end
end
