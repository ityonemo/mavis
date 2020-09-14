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
      list_of_targets = [-47, builtin(:neg_integer), 0, 47,
        builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer),
        builtin(:float), :foo, builtin(:atom), builtin(:reference),
        %Function{return: 0}, builtin(:port), builtin(:pid),
        %Tuple{elements: []}, %Map{}, %Bitstring{size: 0, unit: 0}]

      Enum.each(list_of_targets, fn target ->
        assert {:error, %Message{type: [], target: ^target}} =
          ([] ~> target)
      end)
    end
  end

end
