defmodule TypeTest.Type.Inspect.BasicsTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  @source TypeTest.TypeExample.Basics

  test "any is any" do
    assert "any()" == inspect_type(@source, :any_type)
  end

  test "term is any" do
    assert "any()" == inspect_type(@source, :term_type)
  end

  test "none is none" do
    assert "none()" == inspect_type(@source, :none_type)
  end

  test "pid is pid" do
    assert "pid()" == inspect_type(@source, :pid_type)
  end

  test "port is port" do
    assert "port()" == inspect_type(@source, :port_type)
  end

  test "reference is reference" do
    assert "reference()" == inspect_type(@source, :reference_type)
  end

  test "identifier is a union of pid, port, and reference" do
    assert "identifier()" == inspect_type(@source, :identifier_type)
  end

  describe "corner cases" do
    import Type, only: :macros
    test "non_neg_integer from pos_integer with short range" do
      assert "-1 | non_neg_integer()" == inspect Type.union(-1..0, pos_integer())
    end

    test "non_neg_integer from pos_integer with long range" do
      assert "-10..-1 | non_neg_integer()" == inspect Type.union(-10..0, pos_integer())
    end
  end

end
