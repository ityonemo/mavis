defmodule TypeTest.Type.FetchSpec.NumbersTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  import TypeTest.SpecCase

  @moduletag :fetch

  @source TypeTest.SpecExample.Numbers

  test "literal integers" do
    assert {:ok, identity_for(47)} ==
      Type.fetch_spec(@source, :literal_int_spec, 1)
    assert {:ok, identity_for(-47)} ==
      Type.fetch_spec(@source, :literal_neg_int_spec, 1)
  end

  test "ranges" do
    assert {:ok, identity_for(7..47)} ==
      Type.fetch_spec(@source, :range_spec, 1)
    assert {:ok, identity_for(-47..-7)} ==
      Type.fetch_spec(@source, :neg_range_spec, 1)
  end

  test "builtin float" do
    assert {:ok, identity_for(float())} ==
      Type.fetch_spec(@source, :float_spec, 1)
  end

  test "builtin integers" do
    assert {:ok, identity_for(integer())} ==
      Type.fetch_spec(@source, :integer_spec, 1)
    assert {:ok, identity_for(neg_integer())} ==
      Type.fetch_spec(@source, :neg_integer_spec, 1)
    assert {:ok, identity_for(non_neg_integer())} ==
      Type.fetch_spec(@source, :non_neg_integer_spec, 1)
    assert {:ok, identity_for(pos_integer())} ==
      Type.fetch_spec(@source, :pos_integer_spec, 1)
  end

  test "special classes of integers" do
    assert {:ok, identity_for(0..255)} ==
      Type.fetch_spec(@source, :arity_spec, 1)
    assert {:ok, identity_for(0..255)} ==
      Type.fetch_spec(@source, :byte_spec, 1)
    assert {:ok, identity_for(0..0x10FFFF)} ==
      Type.fetch_spec(@source, :char_spec, 1)
  end

  test "number" do
    assert {:ok, identity_for(number())} == Type.fetch_spec(@source, :number_spec, 1)
  end

  test "timeout" do
    assert {:ok, identity_for(timeout())} == Type.fetch_spec(@source, :timeout_spec, 1)
  end
end
