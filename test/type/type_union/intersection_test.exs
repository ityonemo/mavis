defmodule TypeTest.TypeUnion.IntersectionTest do
  use ExUnit.Case, async: true

  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  describe "unions" do
    test "are all part of any" do
      assert (1 | 3) == Type.intersection((1 | 3), builtin(:any))
      assert (1 | 3) == Type.intersection((1 | 3), (1 | 3))
    end

    test "are disjoint" do
      assert builtin(:none) == Type.intersection((1 | 3), (2 | 5))
    end

    test "get the overlap" do
      #assert (1 | 3) == Type.intersection((0..1 | 3..4), 1..3)
      assert (1 | 3 | 5) == Type.intersection((0..1 | 3..5), (1..3 | 5..6))
    end
  end

end
