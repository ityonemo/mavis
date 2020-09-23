defmodule TypeTest.LiteralAtom.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "a literal atom" do
    test "is a subtype of itself" do
      assert :foo in :foo
    end

    test "is a subtype of builtin atom()" do
      assert :foo in builtin(:atom)
    end

    test "is a subtype of builtin any()" do
      assert :foo in builtin(:any)
    end

    test "is not a subtype of other atoms" do
      refute :foo in :bar
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([:foo, builtin(:atom)])
      |> Enum.each(fn target ->
        refute :foo in target
      end)
    end
  end
end
