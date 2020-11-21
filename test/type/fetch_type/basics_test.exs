defmodule TypeTest.Type.FetchType.BasicsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators

  @moduletag :fetch

  @source TypeTest.TypeExample.Basics

  test "any is any" do
    assert {:ok, any()} == Type.fetch_type(@source, :any_type)
  end

  test "term is any" do
    assert {:ok, any()} == Type.fetch_type(@source, :term_type)
  end

  test "none is none" do
    assert {:ok, none()} == Type.fetch_type(@source, :none_type)
  end

  test "pid is pid" do
    assert {:ok, pid()} == Type.fetch_type(@source, :pid_type)
  end

  test "port is port" do
    assert {:ok, port()} == Type.fetch_type(@source, :port_type)
  end

  test "reference is reference" do
    assert {:ok, reference()} == Type.fetch_type(@source, :reference_type)
  end

  test "identifier is a union of pid, port, and reference" do
    assert {:ok, (pid() <|> port() <|> reference())} ==
      Type.fetch_type(@source, :identifier_type)
  end

end
