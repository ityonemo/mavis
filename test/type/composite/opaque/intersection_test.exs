defmodule TypeTest.TypeOpaque.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection
  @moduletag :opaque

  import Type, only: :macros

  alias Type.Opaque

  @opaque_int %Opaque{
    module: Foo,
    name: :bar,
    params: [],
    type: integer()
  }

  describe "the opaque type" do
    test "does not intersect with a matching type" do
      assert none() == integer() <~> @opaque_int
      assert none() == @opaque_int <~> integer()
    end
  end
end
