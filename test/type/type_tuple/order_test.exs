defmodule TypeTest.TypeTuple.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.Tuple

  describe "a tuple" do
    test "is bigger than bottom and pid" do
      assert %Tuple{elements: []} > builtin(:none)
      assert %Tuple{elements: []} > builtin(:pid)
    end

    test "is bigger when it has more elements" do
      assert %Tuple{elements: [:foo]} > %Tuple{elements: []}
      assert %Tuple{elements: [:bar, :foo]} > %Tuple{elements: [:foo]}
    end

    test "is bigger when its k'th element is more general" do
      assert %Tuple{elements: [builtin(:any)]} > %Tuple{elements: [builtin(:integer)]}
      assert %Tuple{elements: [:foo, builtin(:any)]} > %Tuple{elements: [:foo, builtin(:integer)]}
    end

    test "is smaller than a union containing it" do
      assert %Tuple{elements: [:foo]} < nil <|> %Tuple{elements: [:foo]}
    end

    test "is smaller when it has fewer elements" do
      assert %Tuple{elements: []} < %Tuple{elements: [:foo]}
      assert %Tuple{elements: [:foo]} < %Tuple{elements: [:bar, :foo]}
    end

    test "is smaller when its k'th element is less general" do
      assert %Tuple{elements: [builtin(:integer)]} < %Tuple{elements: [builtin(:any)]}
      assert %Tuple{elements: [:foo, builtin(:integer)]} < %Tuple{elements: [:foo, builtin(:any)]}
    end

    test "is smaller than bitstrings or top" do
      assert %Tuple{elements: []} < %Type.Bitstring{size: 0, unit: 0}
      assert %Tuple{elements: []} < builtin(:any)
    end
  end

  describe "a tuple with 'any' elements" do
    test "is bigger than a tuple with defined elements" do
      assert %Tuple{elements: :any} > %Tuple{elements: []}
      assert %Tuple{elements: :any} > %Tuple{elements: [builtin(:any)]}
      assert %Tuple{elements: :any} > %Tuple{elements: [builtin(:any), builtin(:any)]}
    end
  end

end
