defmodule TypeTest.TypeOpaque.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

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
    test "is usable as any and self" do
      assert :ok = @opaque_int ~> builtin(:any)
      assert :ok = @opaque_int ~> @opaque_int
    end

    test "warns when usable_as is transferred" do
      assert {:maybe, _} = @opaque_int ~> builtin(:integer)
      assert {:maybe, _} = builtin(:integer) ~> @opaque_int
    end
  end
end
