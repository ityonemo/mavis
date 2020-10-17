defmodule TypeTest.TypeOpaque.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  alias Type.Opaque

  @opaque_int %Opaque{
    module: Foo,
    name: :bar,
    params: [],
    type: builtin(:integer)
  }

  describe "the opaque type" do
    test "does not intersect with a matching type" do
      assert builtin(:none) == builtin(:integer) <~> @opaque_int
      assert builtin(:none) == @opaque_int <~> builtin(:integer)
    end
  end
end
