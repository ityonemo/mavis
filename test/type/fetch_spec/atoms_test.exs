defmodule TypeTest.Type.FetchSpec.AtomsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.SpecCase

  @moduletag :fetch

  @source TypeTest.SpecExample.Atoms

  test "literal atoms" do
    assert {:ok, identity_for(:literal)} == Type.fetch_spec(@source, :literal_spec, 1)
  end

  test "atom" do
    assert {:ok, identity_for(atom())} == Type.fetch_spec(@source, :atom_spec, 1)
  end

  test "boolean" do
    assert {:ok, identity_for(true <|> false)} == Type.fetch_spec(@source, :boolean_spec, 1)
  end

  test "module" do
    assert {:ok, identity_for(module())} == Type.fetch_spec(@source, :module_spec, 1)
  end

  test "node" do
    assert {:ok, identity_for(node_type())} == Type.fetch_spec(@source, :node_spec, 1)
  end
end
