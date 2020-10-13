defmodule TypeTest.Type.FetchSpec.BasicsTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import Type.Operators
  import TypeTest.SpecCase

  @moduletag :fetch

  @source TypeTest.SpecExample.Basics

  test "any is any" do
    assert {:ok, identity_for(builtin(:any))} ==
      Type.fetch_spec(@source, :any_spec, 1)
  end

  test "term is any" do
    assert {:ok, identity_for(builtin(:any))} ==
      Type.fetch_spec(@source, :term_spec, 1)
  end

  test "none is none" do
    none_function = %Type.Function{
      params: [builtin(:any)],
      return: builtin(:none)
    }

    assert {:ok, none_function} ==
      Type.fetch_spec(@source, :none_spec, 1)
  end

  test "pid is pid" do
    assert {:ok, identity_for(builtin(:pid))} ==
      Type.fetch_spec(@source, :pid_spec, 1)
  end

  test "port is port" do
    assert {:ok, identity_for(builtin(:port))} ==
      Type.fetch_spec(@source, :port_spec, 1)
  end

  test "reference is reference" do
    assert {:ok, identity_for(builtin(:reference))} ==
      Type.fetch_spec(@source, :reference_spec, 1)
  end

  test "identifier is a union of pid, port, and reference" do
    assert {:ok, identity_for(builtin(:pid) <|> builtin(:port) <|> builtin(:reference))} ==
      Type.fetch_spec(@source, :identifier_spec, 1)
  end

end
