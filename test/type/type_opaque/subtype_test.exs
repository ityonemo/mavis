defmodule TypeTest.TypeOpaque.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Opaque

  @opaque_int %Opaque{
    module: Foo,
    name: :bar,
    params: [],
    type: builtin(:integer)
  }

  describe "the opaque type" do
    test "is disjoint with its underlying type" do
      refute @opaque_int in builtin(:integer)
      refute builtin(:integer) in @opaque_int
    end
  end
end
