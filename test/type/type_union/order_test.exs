defmodule TypeTest.TypeUnion.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "a union" do
    test "is bigger than bottom and pid" do
      assert (1 <|> :foo) > builtin(:none)
      assert (1 <|> :foo) < builtin(:any)
    end

    test "is just bigger than its biggest element" do
      assert (1 <|> 3) > 3
      assert (1 <|> 3) < 4
      assert (1 <|> 3..4) > 3..4
      assert (1..2 <|> 4) < 3..5
      assert (1 <|> 3..4) < 3..5
    end

    test "for integer ranges if everything is in the range it's smaller" do
      assert (1 <|> 3..4) < 0..4
      assert (1..2 <|> 4) < 0..4
    end

    test "is bigger when it's categorically bigger" do
      assert (1 <|> builtin(:atom)) > builtin(:atom)
      assert (1 <|> :atom) > :atom
    end
  end
end
