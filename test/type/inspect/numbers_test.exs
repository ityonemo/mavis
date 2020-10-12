defmodule TypeTest.Type.Inspect.NumbersTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  @source TypeTest.TypeExample.Numbers

  test "literal integers" do
    assert "47" == inspect_type(@source, :literal_int)
    assert "-47" == inspect_type(@source, :literal_neg_int)
  end

  test "ranges" do
    assert "7..47" == inspect_type(@source, :range)
    assert "-47..-7" == inspect_type(@source, :neg_range)
  end

  test "builtin float" do
    assert "float()" == inspect_type(@source, :float_type)
  end

  test "builtin integers" do
    assert "integer()" == inspect_type(@source, :integer_type)
    assert "neg_integer()" == inspect_type(@source, :neg_integer_type)
    assert "non_neg_integer()" == inspect_type(@source, :non_neg_integer_type)
    assert "pos_integer()" == inspect_type(@source, :pos_integer_type)
  end

  test "special classes of integers" do
    assert "0..255" == inspect_type(@source, :arity_type)
    assert "0..255" == inspect_type(@source, :byte_type)
    # unfortunately, we can't override this to produce `char`
    # because we are relying on the builtin inspect protocol
    # for the Range struct.
    assert "0..1114111" == inspect_type(@source, :char_type)
  end

  test "number" do
    assert "number()" ==
      inspect_type(@source, :number_type)
  end

  test "timeout" do
    assert "timeout()" ==
      inspect_type(@source, :timeout_type)
  end
end
