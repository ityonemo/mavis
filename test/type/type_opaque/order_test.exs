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
    test "is ordered just less than its internal type" do
      assert builtin(:integer) > @opaque_int
      assert @opaque_int < builtin(:integer)

      assert builtin(:non_neg_integer) < @opaque_int
      assert @opaque_int > builtin(:non_neg_integer)
    end
  end

end
