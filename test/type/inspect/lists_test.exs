defmodule TypeTest.Type.Inspect.ListsTest do
  use ExUnit.Case, async: true

  import TypeTest.InspectCase
  @moduletag :inspect

  @source TypeTest.TypeExample.Lists

  test "literal/0 is empty list" do
    assert "[]" == inspect_type(@source, :literal_0)
  end

  test "literal/1" do
    assert "[integer()]" == inspect_type(@source, :literal_1)
  end

  test "nonempty any list" do
    assert "[...]" == inspect_type(@source, :nonempty_any)
  end

  test "nonempty typed list" do
    assert "[..., integer()]" == inspect_type(@source, :nonempty_typed)
  end

  test "keyword/1 literal list" do
    assert "[foo: integer()]" == inspect_type(@source, :keyword_literal)
  end

  test "keyword/2 literal list" do
    assert "[bar: float(), foo: integer()]" ==
      inspect_type(@source, :keyword_2_literal)
  end

  test "list/0" do
    assert "list()" == inspect_type(@source, :list_0)
  end

  # NB: list/1 outputs the literal "[<type>]"
  # NB: nonempty_list/1 outputs the literal "[..., <type>]"

  test "maybe_improper_list/2" do
    assert "maybe_improper_list(integer(), nil)" ==
      inspect_type(@source, :maybe_improper_list_2)
  end

  test "nonempty_improper_list/2" do
    assert "nonempty_improper_list(integer(), nil)" ==
      inspect_type(@source, :nonempty_improper_list_2)
  end

  test "nonempty_maybe_improper_list/2" do
    assert "nonempty_maybe_improper_list(integer(), nil)" ==
      inspect_type(@source, :nonempty_maybe_improper_list_2)
  end

  test "charlist" do
    assert "charlist()" == inspect_type(@source, :charlist_type)
  end

  test "nonempty charlist" do
    assert "nonempty_charlist()" ==
      inspect_type(@source, :nonempty_charlist_type)
  end

  test "keyword/0" do
    assert "keyword()" == inspect_type(@source, :keyword_0)
  end

  test "keyword/1" do
    assert "keyword(integer())" ==
      inspect_type(@source, :keyword_1)
  end

  # NB: nonempty_list/0 outputs the literal "[...]

  test "maybe_improper_list/0" do
    assert "maybe_improper_list()" ==
      inspect_type(@source, :maybe_improper_list_0)
  end

  test "nonempty_maybe_improper_list/0" do
    assert "nonempty_maybe_improper_list()" ==
      inspect_type(@source, :nonempty_maybe_improper_list_0)
  end
end
