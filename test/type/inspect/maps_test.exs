defmodule TypeTest.Type.Inspect.MapsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.InspectCase

  @moduletag :inspect

  alias Type.Map

  @source TypeTest.TypeExample.Maps

  test "empty map literal" do
    assert "%{}" == inspect_type(@source, :empty_map_type)
  end

  test "atom key map literal" do
    assert "%{atom: integer()}" == inspect_type(@source, :atom_key_type)
  end

  test "required integer literal type" do
    assert "%{required(0) => integer()}" == inspect %Map{required: %{0 => builtin(:integer)}}
  end

  test "optional literal type" do
    assert "%{optional(:foo) => integer()}" == inspect_type(@source, :optional_literal_type)
  end

  test "struct literal type" do
    assert "%#{inspect @source}{}" ==
      inspect_type(@source, :struct_literal_type)
  end

  test "struct defined literal type" do
    assert "%#{inspect @source}{foo: integer()}" ==
      inspect_type(@source, :struct_defined_literal_type)
  end
end
