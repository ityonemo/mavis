defmodule TypeTest.Type.FetchType.BasicsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  @moduletag :fetch

  @source TypeTest.TypeExample.Basics

  test "any is any" do
    assert {:ok, builtin(:any)} == Type.fetch_type(@source, :any_type)
  end

  test "term is any" do
    assert {:ok, builtin(:any)} == Type.fetch_type(@source, :term_type)
  end

  test "none is none" do
    assert {:ok, builtin(:none)} == Type.fetch_type(@source, :none_type)
  end

  test "pid is pid" do
    assert {:ok, builtin(:pid)} == Type.fetch_type(@source, :pid_type)
  end

  test "port is port" do
    assert {:ok, builtin(:port)} == Type.fetch_type(@source, :port_type)
  end

  test "reference is reference" do
    assert {:ok, builtin(:reference)} == Type.fetch_type(@source, :reference_type)
  end

  test "identifier is a union of pid, port, and reference" do
    assert {:ok, (builtin(:pid) <|> builtin(:port) <|> builtin(:reference))} ==
      Type.fetch_type(@source, :identifier_type)
  end

end
