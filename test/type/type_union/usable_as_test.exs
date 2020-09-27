defmodule TypeTest.TypeUnion.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]
  use Type.Operators

  describe "for union types" do
    test "you can use it for itself and the builtin any" do
      assert :ok = (1 | :foo) ~> (1 | :foo)
      assert :ok = (1 | :foo) ~> builtin(:any)
    end

    test "it's usable as self or a bigger union" do
      assert :ok = (1 | :foo) ~> (1 | :foo)
      assert :ok = (1 | :bar) ~> (1 | :bar | :foo)
    end

    test "it might be usable as one of its elements" do
      assert {:maybe, _} = (1 | :foo) ~> 1
      assert {:maybe, _} = (1 | :foo) ~> :foo
    end
  end

end
