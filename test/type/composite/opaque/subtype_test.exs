defmodule TypeTest.TypeOpaque.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype
  @moduletag :opaque

  import Type, only: :macros

  use Type.Operators

  alias Type.Opaque

  @opaque_int %Opaque{
    module: Foo,
    name: :bar,
    params: [],
    type: integer()
  }

  describe "the opaque type" do
    test "is disjoint with its underlying type" do
      refute @opaque_int in integer()
      refute integer() in @opaque_int
    end
  end
end
