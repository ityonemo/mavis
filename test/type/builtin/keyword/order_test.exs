defmodule TypeTest.BuiltinKeyword.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  alias Type.List

  @ltype byte() <|> binary() <|> keyword()
  @final [] <|> binary()

  # note that the keyword is nonempty false list
  describe "an keyword" do
    test "is bigger than bottom and reference" do
      assert keyword() > none()
      assert keyword() > reference()
    end

    test "is bigger than `less than complete` keyword lists" do
      assert keyword() > list(%Tuple{elements: [atom(), integer()]})
      assert keyword() > list(%Tuple{elements: [:foo, any()]})
    end

    test "is bigger than examples of itself" do
      assert keyword() > []
      assert keyword() > [foo: "bar"]
    end

    test "is smaller than a union containing it" do
      assert keyword() < nil <|> keyword()
    end

    test "is smaller than arbitrary lists, bitstrings or top" do
      assert keyword() < list()
      assert keyword() < bitstring()
      assert keyword() < any()
    end
  end
end
