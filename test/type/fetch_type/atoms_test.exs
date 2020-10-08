defmodule TypeTest.Type.FetchType.AtomsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  @moduletag :fetch

  @source TypeTest.TypeExample.Atoms

  test "literal atoms" do
    assert :literal == Type.fetch_type(@source, :literal_atom)
  end

  test "atom" do
    assert builtin(:atom) == Type.fetch_type(@source, :atom_type)
  end

  test "boolean" do
    assert (true | false) == Type.fetch_type(@source, :boolean_type)
  end

  test "module" do
    assert builtin(:module) == Type.fetch_type(@source, :module_type)
  end

  test "node" do
    assert builtin(:node) == Type.fetch_type(@source, :node_type)
  end
end
