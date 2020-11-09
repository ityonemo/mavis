defmodule TypeTest.TypeOpaque.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.Opaque

  @opaque_int %Opaque{
    module: Foo,
    name: :bar,
    params: [],
    type: builtin(:integer)
  }

  describe "the opaque type" do
    test "is ordered with its internal type's typegroup" do
      # for a simple type
      assert Type.typegroup(builtin(:atom)) == Type.typegroup(builtin(:atom))
      # for a union type
      assert Type.typegroup(@opaque_int) == Type.typegroup(builtin(:integer))
    end

    test "is ordered less than its internal type" do
      assert builtin(:integer) > @opaque_int
      assert @opaque_int < builtin(:integer)

      assert builtin(:non_neg_integer) < @opaque_int
      assert @opaque_int > builtin(:non_neg_integer)
    end
  end

end
