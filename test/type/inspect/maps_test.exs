defmodule TypeTest.Type.Inspect.MapsTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  import Type, only: :macros

  alias Type.Map

  @source TypeTest.TypeExample.Maps

  test "empty map literal" do
    assert "map(%{})" == inspect_type(@source, :empty_map_type)
  end

  test "the any map type" do
    assert "map()" == inspect_type(@source, :any_map_type)
  end

  test "atom key map literal" do
    assert "map(%{atom: integer()})" == inspect_type(@source, :atom_key_type)
  end

  test "required integer literal type" do
    assert "map(%{0 => integer()})" == inspect %Map{required: %{0 => builtin(:integer)}}
  end

  test "optional literal type" do
    assert "map(%{optional(:foo) => integer()})" == inspect_type(@source, :optional_literal_type)
  end

  test "struct literal type" do
    assert "map(%#{inspect @source}{})" ==
      inspect_type(@source, :struct_literal_type)
  end

  test "struct defined literal type" do
    assert "map(%#{inspect @source}{foo: integer()})" ==
      inspect_type(@source, :struct_defined_literal_type)
  end
  
  test "ordering is optionals, then numbers, then atoms" do
    assert "map(%{optional(:foo) => :bar, 0 => :bar, baz: :bar})" ==
      inspect map(%{:baz => :bar, 0 => :bar, optional(:foo) => :bar})
  end
end
