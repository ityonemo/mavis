defmodule TypeTest.Builtin.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.{Bitstring, Function, List, Map, Message, Tuple}

  describe "none" do
    test "is not usable as any type" do
      Enum.each(TypeTest.Targets.except([]), fn target ->
        assert {:error, %Message{type: builtin(:none), target: ^target}} =
            (builtin(:none) ~> target)
        end)
    end
  end

  describe "neg_integer" do
    test "is usable as self, integer and any" do
      assert :ok = builtin(:neg_integer) ~> builtin(:neg_integer)
      assert :ok = builtin(:neg_integer) ~> builtin(:integer)
      assert :ok = builtin(:neg_integer) ~> builtin(:any)
    end

    test "could be usable as a negative number, partially negative range" do
      assert {:maybe, [%Message{type: builtin(:neg_integer), target: -1}]} =
        builtin(:neg_integer) ~> -1
      assert {:maybe, [%Message{type: builtin(:neg_integer), target: -47..-1}]} =
        builtin(:neg_integer) ~> -47..-1
      assert {:maybe, [%Message{type: builtin(:neg_integer), target: -10..10}]} =
        builtin(:neg_integer) ~> -10..10
    end

    test "cannot be usable as a non-negative number, or positive range" do
      assert {:error, %Message{type: builtin(:neg_integer), target: 42}} =
        builtin(:neg_integer) ~> 42
      assert {:error, %Message{type: builtin(:neg_integer), target: 0..42}} =
        builtin(:neg_integer) ~> 0..42
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([-47, builtin(:neg_integer), builtin(:integer), 0, 47, -10..10]),
        fn target ->
          assert {:error, %Message{type: builtin(:neg_integer), target: ^target}} =
              (builtin(:neg_integer) ~> target)
        end)
    end
  end

  describe "non_neg_integer" do
    test "is usable as self, integer and any" do
      assert :ok = builtin(:non_neg_integer) ~> builtin(:non_neg_integer)
      assert :ok = builtin(:non_neg_integer) ~> builtin(:integer)
      assert :ok = builtin(:non_neg_integer) ~> builtin(:any)
    end

    test "could be usable as a non negative number, positive number, partially non negative range" do
      assert {:maybe, [%Message{type: builtin(:non_neg_integer), target: 0}]} =
        builtin(:non_neg_integer) ~> 0
      assert {:maybe, [%Message{type: builtin(:non_neg_integer), target: 47}]} =
        builtin(:non_neg_integer) ~> 47
      assert {:maybe, [%Message{type: builtin(:non_neg_integer), target: 0..47}]} =
        builtin(:non_neg_integer) ~> 0..47
      assert {:maybe, [%Message{type: builtin(:non_neg_integer), target: -10..10}]} =
        builtin(:non_neg_integer) ~> -10..10
    end

    test "cannot be usable as a negative number, or negative range" do
      assert {:error, %Message{type: builtin(:non_neg_integer), target: -42}} =
        builtin(:non_neg_integer) ~> -42
      assert {:error, %Message{type: builtin(:non_neg_integer), target: -42..-1}} =
        builtin(:non_neg_integer) ~> -42..-1
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([builtin(:non_neg_integer), builtin(:pos_integer),
                                 builtin(:integer), 0, 47, -10..10]),
        fn target ->
          assert {:error, %Message{type: builtin(:non_neg_integer), target: ^target}} =
              (builtin(:non_neg_integer) ~> target)
        end)
    end
  end


end
