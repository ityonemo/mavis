defmodule TypeTest.LiteralAtom.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "atoms are usable as" do
    test "themselves" do
      assert (:foo ~> :foo) == :ok
    end

    test "atoms" do
      assert (:foo ~> builtin(:atom)) == :ok
    end

    test "any" do
      assert (:foo ~> builtin(:any)) == :ok
    end
  end

  alias Type.{Bitstring, Function, List, Map, Message, Tuple}

  describe "atoms not usable as" do
    test "any other type" do
      list_of_targets = [-47, builtin(:neg_integer), 0, 47,
        builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer),
        builtin(:float), :foo, builtin(:reference), %Function{return: 0},
        builtin(:port), builtin(:pid), %Tuple{elements: []}, %Map{}, [],
        %List{}, %Bitstring{size: 0, unit: 0}]

      Enum.each(list_of_targets, fn target ->
        assert {:error, %Message{type: :bar, target: ^target}} =
          (:bar ~> target)
      end)
    end
  end

end
