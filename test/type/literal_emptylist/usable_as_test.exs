defmodule TypeTest.LiteralEmptyList.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  alias Type.{Bitstring, List, Message}

  describe "empty list are usable as" do
    test "themselves" do
      assert ([] ~> []) == :ok
    end

    test "lists" do
      assert ([] ~> builtin(:list)) == :ok
      assert ([] ~> list(:foo)) == :ok
    end

    test "a union with list" do
      assert ([] ~> ([] <|> builtin(:atom))) == :ok
      assert ([] ~> (builtin(:list) <|> builtin(:atom))) == :ok
    end

    test "any" do
      assert ([] ~> builtin(:any)) == :ok
    end
  end

  describe "empty list not usable as" do
    test "a nonempty list" do
      assert {:error, %Message{type: [], target: list(...)}} =
        ([] ~> list(...))
    end

    test "a list with a different final" do
      final_list = %List{final: %Bitstring{size: 0, unit: 8}}
      assert {:error, %Message{type: [], target: ^final_list}} =
        ([] ~> final_list)
    end

    test "a union without list" do
      assert {:error, _} = ([] ~> (builtin(:integer) <|> builtin(:float)))
    end

    test "any other type" do
      targets = TypeTest.Targets.except([[], builtin(:list)])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: [], target: ^target}} =
          ([] ~> target)
      end)
    end
  end

end
