defmodule TypeTest.Type.FetchType.ListsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  @moduletag :fetch

  @source TypeTest.TypeExample.Lists

  alias Type.NonemptyList

  test "literal/0 is empty list" do
    assert {:ok, []} == Type.fetch_type(@source, :literal_0)
  end

  test "literal/1" do
    assert {:ok, list(integer())} == Type.fetch_type(@source, :literal_1)
  end

  test "nonempty any list" do
    assert {:ok, list(...)} == Type.fetch_type(@source, :nonempty_any)
  end

  test "nonempty typed list" do
    assert {:ok, list(integer(), ...)} == Type.fetch_type(@source, :nonempty_typed)
  end

  test "keyword/1 literal list" do
    foo_integer = tuple({:foo, integer()})
    assert {:ok, list(foo_integer)} == Type.fetch_type(@source, :keyword_literal)
  end

  test "keyword/2 literal list" do
    keyword_type = tuple({:foo, integer()}) <|> tuple({:bar, float()})
    assert {:ok, list(keyword_type)} == Type.fetch_type(@source, :keyword_2_literal)
  end

  test "list/0" do
    assert {:ok, list()} == Type.fetch_type(@source, :list_0)
  end

  test "list/1" do
    assert {:ok, list(integer())} == Type.fetch_type(@source, :list_1)
  end

  test "nonempty_list/1" do
    assert {:ok, list(integer(), ...)} == Type.fetch_type(@source, :nonempty_list_1)
  end

  test "maybe_improper_list/2" do
    assert {:ok, maybe_improper_list(integer(), nil)} ==
      Type.fetch_type(@source, :maybe_improper_list_2)
  end

  test "nonempty_improper_list/2" do
    assert {:ok, nonempty_improper_list(integer(), nil)} ==
      Type.fetch_type(@source, :nonempty_improper_list_2)
  end

  test "nonempty_maybe_improper_list/2" do
    assert {:ok, nonempty_maybe_improper_list(integer(), nil)} ==
      Type.fetch_type(@source, :nonempty_maybe_improper_list_2)
  end

  test "charlist" do
    assert {:ok, list(0..0x10_FFFF)} == Type.fetch_type(@source, :charlist_type)
  end

  test "nonempty charlist" do
    assert {:ok, list(0..0x10_FFFF, ...)} == Type.fetch_type(@source, :nonempty_charlist_type)
  end

  test "keyword/0" do
    assert {:ok, list(tuple({atom(), any()}))} ==
      Type.fetch_type(@source, :keyword_0)
  end

  test "keyword/1" do
    assert {:ok, list(tuple({atom(), integer()}))} ==
      Type.fetch_type(@source, :keyword_1)
  end

  test "nonempty_list/0" do
    assert {:ok, list(...)} ==
      Type.fetch_type(@source, :nonempty_list_0)
  end

  test "maybe_improper_list/0" do
    assert {:ok, maybe_improper_list()} ==
      Type.fetch_type(@source, :maybe_improper_list_0)
  end

  test "nonempty_maybe_improper_list/0" do
    assert {:ok, nonempty_maybe_improper_list()} ==
      Type.fetch_type(@source, :nonempty_maybe_improper_list_0)
  end
end
