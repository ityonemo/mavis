defmodule TypeTest.LiteralAtom.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  describe "a literal atom" do
    test "is a subtype of itself" do
      assert :foo in :foo
    end

    test "is a subtype of builtin atom()" do
      assert :foo in atom()
    end

    test "is a subtype of builtin any()" do
      assert :foo in any()
    end

    test "is a subtype of node when it has node form" do
      assert :nonode@nohost in node_type()
      refute :foobar in node_type()
    end

    test "is a subtype of module when it is a module" do
      assert Kernel in module()
      refute :foobar in module()
    end

    test "is a subtype of a union with itself or atom" do
      assert :foo in (:foo <|> :bar)
      assert :foo in (:foo <|> integer())
      assert :foo in (atom() <|> integer())
    end

    test "is not a subtype of a union with orthogonal types" do
      refute :foo in (integer() <|> :infinity)
    end

    test "is not a subtype of other atoms" do
      refute :foo in :bar
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([:foo, atom()])
      |> Enum.each(fn target ->
        refute :foo in target
      end)
    end
  end
end
