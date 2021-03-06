defmodule TypeTest.Type.FetchType.MapsTest do
  use ExUnit.Case, async: true
  @moduletag :fetch

  import Type, only: :macros

  alias Type.Map

  @source TypeTest.TypeExample.Maps

  test "empty map literal" do
    assert {:ok, %Map{}} == Type.fetch_type(@source, :empty_map_type)
  end

  test "atom key map literal" do
    assert {:ok, map(%{atom: integer()})} ==
      Type.fetch_type(@source, :atom_key_type)
  end

  test "required literal type" do
    assert {:ok, map(%{foo: integer()})} ==
      Type.fetch_type(@source, :required_literal_type)
  end

  test "optional literal type" do
    assert {:ok, map(%{optional(:foo) => integer()})} ==
      Type.fetch_type(@source, :optional_literal_type)
  end

  test "struct literal type" do
    assert {:ok, map(%{__struct__: @source, foo: any()})} ==
      Type.fetch_type(@source, :struct_literal_type)
  end

  test "struct defined literal type" do
    assert {:ok, map(%{__struct__: @source, foo: integer()})} ==
      Type.fetch_type(@source, :struct_defined_literal_type)
  end

  test "downgraded nonliteral type" do
    assert {:ok, map(%{optional(integer()) => integer()})} ==
      Type.fetch_type(@source, :downgraded_key_type)
  end
end
