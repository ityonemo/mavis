defmodule TypeTest.LiteralRange.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "ranges are usable as" do
    test "themselves" do
      assert (0..47 ~> 0..47) == :ok
    end

    test "integer subtypes" do
      assert (1..47 ~> builtin(:pos_integer)) == :ok
      assert (0..47 ~> builtin(:non_neg_integer)) == :ok
      assert (-47..-1 ~> builtin(:neg_integer)) == :ok
      assert (1..47 ~> builtin(:integer)) == :ok
    end

    test "bigger ranges" do
      assert (1..47 ~> 1..50) == :ok
      assert (1..47 ~> 0..47) == :ok
      assert (1..47 ~> 0..50) == :ok
    end

    test "any" do
      assert (1..47 ~> builtin(:any)) == :ok
    end
  end

  alias Type.{Bitstring, Function, List, Map, Message, Tuple}

  describe "ranges maybe usable as" do
    test "an in-range integer" do
      assert {:maybe, [%Message{type: 0..47, target: 42}]} =
        (0..47 ~> 42)
      assert {:maybe, [%Message{type: 0..47, target: 0}]} =
        (0..47 ~> 0)
      assert {:maybe, [%Message{type: 0..47, target: 47}]} =
        (0..47 ~> 47)
    end

    test "partially overlapping or internal ranges" do
      assert {:maybe, [%Message{type: 0..47, target: 42..100}]} =
        (0..47 ~> 42..100)
      assert {:maybe, [%Message{type: 0..47, target: -10..42}]} =
        (0..47 ~> -10..42)
      assert {:maybe, [%Message{type: 0..47, target: 10..42}]} =
        (0..47 ~> 10..42)
    end

    test "a partially overlapping integer subtype" do
      assert {:maybe, [%Message{type: -10..10, target: builtin(:pos_integer)}]} =
        (-10..10 ~> builtin(:pos_integer))
      assert {:maybe, [%Message{type: -10..10, target: builtin(:neg_integer)}]} =
        (-10..10 ~> builtin(:neg_integer))
      assert {:maybe, [%Message{type: -10..10, target: builtin(:non_neg_integer)}]} =
        (-10..10 ~> builtin(:non_neg_integer))
    end
  end

  describe "ranges not usable as" do
    test "an out of range integer or range" do
      assert {:error, %Message{type: 0..47, target: 50}} =
        (0..47 ~> 50)
      assert {:error, %Message{type: 0..47, target: 50..100}} =
        (0..47 ~> 50..100)
      assert {:error, %Message{type: 0..47, target: -47..-42}} =
        (0..47 ~> -47..-42)
    end

    test "an incompatible integer subtype" do
      assert {:error, %Message{type: -10..0, target: builtin(:pos_integer)}} =
        (-10..0 ~> builtin(:pos_integer))
      assert {:error, %Message{type: 2..10, target: builtin(:neg_integer)}} =
        (2..10 ~> builtin(:neg_integer))
      assert {:error, %Message{type: -10..-1, target: builtin(:non_neg_integer)}} =
        (-10..-1 ~> builtin(:non_neg_integer))
    end

    test "any other type" do
      list_of_targets = [builtin(:float), :foo, builtin(:atom),
        builtin(:reference), %Function{return: 0}, builtin(:port),
        builtin(:pid), %Tuple{elements: []}, %Map{}, [],
        %List{}, %Bitstring{size: 0, unit: 0}]

      Enum.each(list_of_targets, fn target ->
        assert {:error, %Message{type: 0..47, target: ^target}} =
          (0..47 ~> target)
      end)
    end
  end

end
