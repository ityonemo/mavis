defmodule TypeTest.Type.Inspect.AtomsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.InspectCase

  @moduletag :inspect

  @source TypeTest.TypeExample.Atoms

  test "literal atoms" do
    assert ":literal" == inspect_type(@source, :literal_atom)
  end

  test "atom" do
    assert "atom()" == inspect_type(@source, :atom_type)
  end

  test "boolean" do
    assert "boolean()" == inspect_type(@source, :boolean_type)
  end

  test "boolean or nil" do
    assert "boolean() | nil" == inspect_type(@source, :boolean_or_nil)
  end

  test "module" do
    assert "module()" == inspect_type(@source, :module_type)
  end

  test "node" do
    assert "node()" == inspect_type(@source, :node_type)
  end
end
