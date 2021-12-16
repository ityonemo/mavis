defmodule TypeTest.LiteralAtom.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  describe "atoms are usable as" do
    test "themselves" do
      assert (:foo ~> :foo) == :ok
    end

    test "atoms" do
      assert (:foo ~> atom()) == :ok
    end

    test "a union with atoms" do
      assert (:foo ~> (:foo <|> 1..47)) == :ok
      assert (:foo ~> (atom() <|> 47)) == :ok
    end

    test "node, when they have the right form" do
      assert :ok == :nonode@nohost ~> type(node())
    end

    test "module, when they are modules" do
      assert :ok == Kernel ~> module()
    end

    test "any" do
      assert (:foo ~> any()) == :ok
    end
  end

  describe "atoms are maybe usable" do
    test "as modules if they aren't modules" do
      assert :ok = :foobar ~> module()
      flunk("but also we need to check to make sure that this check is stored")
    end
  end

  alias Type.Message
  alias TypeTest.Targets

  describe "atoms not usable as" do
    test "a union without atoms" do
      assert {:error, _} = (:foo ~> (integer() <|> float()))
    end

    test "node, when they don't have the right form" do
      assert {:error, _} = :foobar ~> type(node())
    end

    test "any other type" do
      targets = Targets.except([atom()])
      Enum.each(targets, fn target ->
        assert {:error, %Message{challenge: :bar, target: ^target}} =
          (:bar ~> target)
      end)
    end
  end

end
