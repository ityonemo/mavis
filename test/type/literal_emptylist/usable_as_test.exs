defmodule TypeTest.LiteralEmptyList.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.{Bitstring, Function, List, Map, Message, Tuple}

  describe "empty list are usable as" do
    test "themselves" do
      assert ([] ~> []) == :ok
    end

    test "lists" do
      assert ([] ~> %List{type: builtin(:any)}) == :ok
      assert ([] ~> %List{type: :foo}) == :ok
    end

    test "any" do
      assert ([] ~> builtin(:any)) == :ok
    end
  end

  describe "empty list not usable as" do
    test "a nonempty list" do
      assert ([] ~> %List{nonempty: true})
    end

    test "a list with a different final" do
      assert ([] ~> %List{final: %Bitstring{size: 0, unit: 8}})
    end

    test "any other type" do
      targets = TypeTest.Targets.except([[], %Type.List{}])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: [], target: ^target}} =
          ([] ~> target)
      end)
    end
  end

end
