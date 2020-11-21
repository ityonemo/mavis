defmodule TypeTest.Type.FetchSpec.ListsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.SpecCase

  @moduletag :fetch

  @source TypeTest.SpecExample.Lists

  alias Type.List

  test "literal/0 is empty list" do
    assert {:ok, identity_for([])} == Type.fetch_spec(@source, :literal_0_spec, 1)
  end

  test "literal/1" do
    assert {:ok, identity_for(list(integer()))} ==
      Type.fetch_spec(@source, :literal_1_spec, 1)
  end

  test "nonempty any list" do
    assert {:ok, identity_for(list(...))} ==
      Type.fetch_spec(@source, :nonempty_any_spec, 1)
  end

  test "nonempty typed list" do
    assert {:ok, identity_for(list(integer(), ...))} ==
      Type.fetch_spec(@source, :nonempty_typed_spec, 1)
  end

  test "keyword/1 literal list" do
    foo_integer = tuple({:foo, integer()})

    assert {:ok, identity_for(list(foo_integer))} ==
      Type.fetch_spec(@source, :keyword_literal_spec, 1)
  end

  test "keyword/2 literal list" do
    keyword_type = tuple({:foo, integer()}) <|> tuple({:bar, float()})
    assert {:ok, identity_for(list(keyword_type))} ==
      Type.fetch_spec(@source, :keyword_2_literal_spec, 1)
  end

  test "list/0" do
    assert {:ok, identity_for(list())} ==
      Type.fetch_spec(@source, :list_0_spec, 1)
  end

  test "list/1" do
    assert {:ok, identity_for(list(integer()))} ==
      Type.fetch_spec(@source, :list_1_spec, 1)
  end

  test "nonempty_list/1" do
    assert {:ok, identity_for(list(integer(), ...))} ==
      Type.fetch_spec(@source, :nonempty_list_1_spec, 1)
  end

  test "maybe_improper_list/2" do
    assert {:ok, identity_for(%List{type: integer(), final: (nil <|> [])})} ==
      Type.fetch_spec(@source, :maybe_improper_list_2_spec, 1)
  end

  test "nonempty_improper_list/2" do
    assert {:ok, identity_for(%List{type: integer(), nonempty: true, final: nil})} ==
      Type.fetch_spec(@source, :nonempty_improper_list_2_spec, 1)
  end

  test "nonempty_maybe_improper_list/2" do
    assert {:ok, identity_for(%List{type: integer(), nonempty: true, final: (nil <|> [])})} ==
      Type.fetch_spec(@source, :nonempty_maybe_improper_list_2_spec, 1)
  end

  test "charlist" do
    assert {:ok, identity_for(list(0..0x10_FFFF))} ==
      Type.fetch_spec(@source, :charlist_spec, 1)
  end

  test "nonempty charlist" do
    assert {:ok, identity_for(list(0..0x10_FFFF, ...))} ==
      Type.fetch_spec(@source, :nonempty_charlist_spec, 1)
  end

  test "keyword/0" do
    assert {:ok, identity_for(list(tuple({atom(), any()})))} ==
      Type.fetch_spec(@source, :keyword_0_spec, 1)
  end

  test "keyword/1" do
    assert {:ok, identity_for(list(tuple({atom(), integer()})))} ==
      Type.fetch_spec(@source, :keyword_1_spec, 1)
  end

  test "nonempty_list/0" do
    assert {:ok, identity_for(list(...))} ==
      Type.fetch_spec(@source, :nonempty_list_0_spec, 1)
  end

  test "maybe_improper_list/0" do
    assert {:ok, identity_for(%List{final: any()})} ==
      Type.fetch_spec(@source, :maybe_improper_list_0_spec, 1)
  end

  test "nonempty_maybe_improper_list/0" do
    assert {:ok, identity_for(%List{final: any(), nonempty: true})} ==
      Type.fetch_spec(@source, :nonempty_maybe_improper_list_0_spec, 1)
  end
end
