defmodule TypeTest.TypeOpaque.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

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
    test "is usable as any and self" do
      assert :ok = @opaque_int ~> any()
      assert :ok = @opaque_int ~> @opaque_int
    end

    test "warns when usable_as is transferred" do
      assert {:maybe, _} = @opaque_int ~> integer()
      assert {:maybe, _} = integer() ~> @opaque_int
    end
  end
end
