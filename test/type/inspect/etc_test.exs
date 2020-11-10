defmodule TypeTest.Type.Inspect.EtcTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.InspectCase
  @moduletag :inspect

  @unions TypeTest.TypeExample.Unions
  @remote TypeTest.TypeExample.Remote
  @opq TypeTest.TypeExample.Opaque

  test "union (of atoms)" do
    assert ":bar | :foo" == inspect_type(@unions, :of_atoms)
  end

  describe "remote type" do
    test "basic case" do
      assert "String.t()" == inspect_type(@remote, :elixir_string)
    end
    test "with arity" do
      assert "Foo.bar(integer())" == inspect_type(@remote, :foobar)
    end
    test "String.t(integer) special case" do
      assert "String.t()" == inspect remote(String.t(4))
    end
  end

  test "opaque type" do
    assert "TypeTest.TypeExample.Opaque.opaque()" == inspect_type(@opq, :opaque)
  end
end
