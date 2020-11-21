defmodule TypeTest.Type.FetchSpec.MapsTest do
  use ExUnit.Case, async: true
  @moduletag :fetch

  import Type, only: :macros

  import TypeTest.SpecCase

  alias Type.Map

  @source TypeTest.SpecExample.Maps

  test "empty map literal" do
    assert {:ok, identity_for(%Map{})} == Type.fetch_spec(@source, :empty_map_spec, 1)
  end

  test "atom key map literal" do
    assert {:ok, identity_for(map(%{atom: integer()}))} ==
      Type.fetch_spec(@source, :atom_key_spec, 1)
  end

  test "required literal type" do
    assert {:ok, identity_for(map(%{foo: integer()}))} ==
      Type.fetch_spec(@source, :required_literal_spec, 1)
  end

  test "optional literal type" do
    assert {:ok, identity_for(map(%{optional(:foo) => integer()}))} ==
      Type.fetch_spec(@source, :optional_literal_spec, 1)
  end

  test "struct literal type" do
    assert {:ok, identity_for(map(%{__struct__: @source, foo: any()}))} ==
      Type.fetch_spec(@source, :struct_literal_spec, 1)
  end

  test "struct defined literal type" do
    assert {:ok, identity_for(map(%{__struct__: @source, foo: integer()}))} ==
      Type.fetch_spec(@source, :struct_defined_literal_spec, 1)
  end
end
