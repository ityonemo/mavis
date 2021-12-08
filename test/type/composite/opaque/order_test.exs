defmodule TypeTest.TypeOpaque.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order
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
    test "is ordered with its internal type's typegroup" do
      # for a simple type
      assert Type.typegroup(atom()) == Type.typegroup(atom())
      # for a union type
      assert Type.typegroup(@opaque_int) == Type.typegroup(integer())
    end

    test "is ordered less than its internal type" do
      assert integer() > @opaque_int
      assert @opaque_int < integer()

      assert non_neg_integer() < @opaque_int
      assert @opaque_int > non_neg_integer()
    end
  end

end
