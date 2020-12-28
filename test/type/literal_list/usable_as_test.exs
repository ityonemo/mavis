defmodule TypeTest.LiteralList.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  @list [:foo, :bar]

  describe "literal lists are usable as" do
    test "themselves" do
      assert (@list ~> @list) == :ok
    end

    test "lists" do
      assert (@list ~> list()) == :ok
    end

    test "well-determined lists" do
      assert (@list ~> list(:foo <|> :bar)) == :ok
      assert (@list ~> list(:foo <|> :bar <|> :baz)) == :ok
    end

    test "a union with either itself or float" do
      assert @list ~> (list() <|> :infinity) == :ok
      assert @list ~> (@list <|> :infinity) == :ok
    end

    test "any" do
      assert (@list ~> any()) == :ok
    end
  end

  alias Type.Message

  describe "lists maybe" do
    test "usable as literal lists" do
      assert {:maybe, _} = list() ~> @list
      assert {:maybe, _} = list(atom()) ~> @list
      assert {:maybe, _} = list(:foo <|> :bar) ~> @list
      assert {:maybe, _} = list(:foo <|> :bar <|> :baz) ~> @list
    end
  end

  describe "literal lists not usable as" do
    test "other literal lists" do
      assert {:error, %Message{type: @list, target: literal([:foo])}} =
        (@list ~> literal([:foo]))

      assert {:error, %Message{type: @list, target: literal([:foo, "bar"])}} =
        (@list ~> literal([:foo, "bar"]))

      assert {:error, %Message{type: @list, target: literal([:foo, :bar, :baz])}} =
        (@list ~> literal([:foo, :bar, :baz]))
    end

    test "underdetermined lists" do
      assert {:error, %Message{type: @list, target: list(:foo)}} =
        (@list ~> list(:foo))
    end

    test "a union with a disjoint categories" do
      assert {:error, _} = @list ~> (atom() <|> pid())
    end

    test "any other type" do
      targets = TypeTest.Targets.except([list()])
      Enum.each(targets, fn target ->
        assert {:error, %Message{type: @list, target: ^target}} =
          (@list ~> target)
      end)
    end
  end

  describe "lists not" do
    test "usable as literal lists when types don't match " do
      assert {:error, _} = list(:foo) ~> @list
    end
  end
end
