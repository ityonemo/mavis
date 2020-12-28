defmodule TypeTest.LiteralList.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  @list [:foo, :bar]

  describe "literal lists are usable as" do
    test "themselves" do
      assert (literal(@list) ~> literal(@list)) == :ok
    end

    test "lists" do
      assert (literal(@list) ~> list()) == :ok
    end

    test "well-determined lists" do
      assert (literal(@list) ~> list(:foo <|> :bar)) == :ok
      assert (literal(@list) ~> list(:foo <|> :bar <|> :baz)) == :ok
    end

    test "a union with either itself or float" do
      assert literal(@list) ~> (list() <|> :infinity) == :ok
      assert literal(@list) ~> (literal(@list) <|> :infinity) == :ok
    end

    test "any" do
      assert (literal(@list) ~> any()) == :ok
    end
  end

  alias Type.Message

  describe "lists maybe" do
    test "usable as literal lists" do
      assert {:maybe, _} = list() ~> literal(@list)
      assert {:maybe, _} = list(atom()) ~> literal(@list)
      assert {:maybe, _} = list(:foo <|> :bar) ~> literal(@list)
      assert {:maybe, _} = list(:foo <|> :bar <|> :baz) ~> literal(@list)
    end
  end

  describe "literal lists not usable as" do
    test "other literal lists" do
      assert {:error, %Message{type: literal(@list), target: literal([:foo])}} =
        (literal(@list) ~> literal([:foo]))

      assert {:error, %Message{type: literal(@list), target: literal([:foo, "bar"])}} =
        (literal(@list) ~> literal([:foo, "bar"]))

      assert {:error, %Message{type: literal(@list), target: literal([:foo, :bar, :baz])}} =
        (literal(@list) ~> literal([:foo, :bar, :baz]))
    end

    test "underdetermined lists" do
      assert {:error, %Message{type: literal(@list), target: list(:foo)}} =
        (literal(@list) ~> list(:foo))
    end

    test "a union with a disjoint categories" do
      assert {:error, _} = literal(@list) ~> (atom() <|> pid())
    end

    test "any other type" do
      targets = TypeTest.Targets.except([list()])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: literal(@list), target: ^target}} =
          (literal(@list) ~> target)
      end)
    end
  end

  describe "lists not" do
    test "usable as literal lists when types don't match " do
      assert {:error, _} = list(:foo) ~> literal(@list)
    end
  end
end
