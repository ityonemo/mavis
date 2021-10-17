defmodule TypeTest.TypeUnion.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  describe "union types" do
    test "are in themselves and in any" do
      assert (1 <|> :foo) in (1 <|> :foo)
      assert (1 <|> :foo) in any()
    end

    test "can be in more general unions" do
      assert (1 <|> :foo) in (integer() <|> atom())
    end

    test "can be totally inside of a single type" do
      assert (:foo <|> :bar) in atom()
    end

    test "are not inside if a single element doesn't match" do
      refute (1 <|> :foo) in integer()
      refute (1 <|> :foo) in atom()
    end
  end

end
