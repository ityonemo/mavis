defmodule TypeTest.TypeUnion.IntersectionTest do
  use ExUnit.Case, async: true

  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "unions" do
    @tag :skip
    test "are all part of any" do
      assert (1 <|> 3) == (1 <|> 3) <~> any()
      assert (1 <|> 3) == (1 <|> 3) <~> (1 <|> 3)
    end

    @tag :skip
    test "are disjoint" do
      assert none() == (1 <|> 3) <~> (2 <|> 5)
    end

    @tag :skip
    test "get the overlap" do
      assert (1 <|> 3) == (0..1 <|> 3..4) <~> 1..3
      assert (1 <|> 3 <|> 5) == (0..1 <|> 3..5) <~> (1..3 <|> 5..6)
    end
  end

end
