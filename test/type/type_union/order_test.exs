defmodule TypeTest.TypeUnion.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

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

    test "is bigger than the same union, with one larger elements" do
      assert (0 <|> 2) < (0 <|> 3)
      assert (0 <|> 2) < (1 <|> 2)
    end

    test "is bigger than the same union, with fewer elements" do
      assert (0 <|> 2) < (-2 <|> 0 <|> 2)
    end
  end
end
