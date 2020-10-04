defmodule TypeTest.TypeUnion.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "union types" do
    test "are in themselves and in any" do
      assert (1 | :foo) in (1 | :foo)
      assert (1 | :foo) in builtin(:any)
    end

    test "can be in more general unions" do
      assert (1 | :foo) in (builtin(:integer) | builtin(:atom))
    end

    test "can be totally inside of a single type" do
      assert (:foo | :bar) in builtin(:atom)
    end

    test "are not inside if a single element doesn't match" do
      refute (1 | :foo) in builtin(:integer)
      refute (1 | :foo) in builtin(:atom)
    end
  end

end
