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

    test "is a subtype of node when it has node form" do
      assert :nonode@nohost in builtin(:node)
      refute :foobar in builtin(:node)
    end

    test "is a subtype of module when it is a module" do
      assert Kernel in builtin(:module)
      refute :foobar in builtin(:module)
    end

    test "is a subtype of a union with itself or atom" do
      assert :foo in (:foo <|> :bar)
      assert :foo in (:foo <|> builtin(:integer))
      assert :foo in (builtin(:atom) <|> builtin(:integer))
    end

    test "is not a subtype of a union with orthogonal types" do
      refute :foo in (builtin(:integer) <|> :infinity)
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
