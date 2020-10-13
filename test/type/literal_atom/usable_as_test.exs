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

    test "a union with atoms" do
      assert (:foo ~> (:foo <|> 1..47)) == :ok
      assert (:foo ~> (builtin(:atom) <|> 47)) == :ok
    end

    test "any" do
      assert (:foo ~> builtin(:any)) == :ok
    end
  end

  alias Type.Message
  alias TypeTest.Targets

  describe "atoms not usable as" do
    test "a union without atoms" do
      assert {:error, _} = (:foo ~> (builtin(:integer) <|> builtin(:float)))
    end

    test "any other type" do
      targets = Targets.except([builtin(:atom)])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: :bar, target: ^target}} =
          (:bar ~> target)
      end)
    end
  end

end
