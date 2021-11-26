defmodule TypeTest.BuiltinKeyword.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  alias Type.List
  alias Type.Tuple

  @ltype byte() <|> binary() <|> keyword()
  @final [] <|> binary()

  # note that the keyword is nonempty false list
  describe "keyword/0" do
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

    test "is bigger than keyword/1" do
      assert keyword() > keyword(:foo)
    end

    test "is smaller than a union containing it" do
      assert keyword() < (nil <|> keyword())
    end

    test "is smaller than arbitrary lists, bitstrings or top" do
      assert keyword() < list()
      assert keyword() < bitstring()
      assert keyword() < any()
    end
  end

  describe "keyword/1" do
    test "is bigger than bottom and reference" do
      assert keyword(:foo) > none()
      assert keyword(:foo) > reference()
    end

    test "is bigger than `less than complete` keyword lists" do
      assert keyword(atom()) > list(%Tuple{elements: [atom(), :foo]})
      assert keyword(:foo) > list(%Tuple{elements: [:foo, :foo]})
    end

    test "is bigger than examples of itself" do
      assert keyword(:foo) > []
      assert keyword(:foo) > [foo: :foo]
    end

    test "is smaller than keyword/0" do
      assert keyword(:foo) < keyword()
    end

    test "is smaller than a union containing it" do
      assert keyword(:foo) < (nil <|> keyword(:foo))
    end

    test "is smaller than arbitrary lists, bitstrings or top" do
      assert keyword(:foo) < list()
      assert keyword(:foo) < bitstring()
      assert keyword(:foo) < any()
    end
  end
end
