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
      assert {:maybe, [%Message{type: builtin(:non_neg_integer), target: builtin(:pos_integer)}]} =
        builtin(:non_neg_integer) ~> builtin(:pos_integer)
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

  describe "pos_integer" do
    test "is usable as self, integer and any" do
      assert :ok = builtin(:pos_integer) ~> builtin(:pos_integer)
      assert :ok = builtin(:pos_integer) ~> builtin(:non_neg_integer)
      assert :ok = builtin(:pos_integer) ~> builtin(:integer)
      assert :ok = builtin(:pos_integer) ~> builtin(:any)
    end

    test "could be usable as a positive number, partially positive range" do
      assert {:maybe, [%Message{type: builtin(:pos_integer), target: 1}]} =
        builtin(:pos_integer) ~> 1
      assert {:maybe, [%Message{type: builtin(:pos_integer), target: 1..47}]} =
        builtin(:pos_integer) ~> 1..47
      assert {:maybe, [%Message{type: builtin(:pos_integer), target: -10..10}]} =
        builtin(:pos_integer) ~> -10..10
    end

    test "cannot be usable as a negative number, negative range" do
      assert {:error, %Message{type: builtin(:pos_integer), target: -42}} =
        builtin(:pos_integer) ~> -42
      assert {:error, %Message{type: builtin(:pos_integer), target: 0}} =
        builtin(:pos_integer) ~> 0
      assert {:error, %Message{type: builtin(:pos_integer), target: -42..0}} =
        builtin(:pos_integer) ~> -42..0
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([builtin(:pos_integer), builtin(:non_neg_integer),
          builtin(:integer), 0, 47, -10..10]),
        fn target ->
          assert {:error, %Message{type: builtin(:pos_integer), target: ^target}} =
              (builtin(:pos_integer) ~> target)
        end)
    end
  end

  describe "integer" do
    test "is usable as self, integer and any" do
      assert :ok = builtin(:integer) ~> builtin(:integer)
      assert :ok = builtin(:integer) ~> builtin(:any)
    end

    test "could be usable as a number, or range" do
      assert {:maybe, [%Message{type: builtin(:integer), target: 1}]} =
        builtin(:integer) ~> 1
      assert {:maybe, [%Message{type: builtin(:integer), target: 1..47}]} =
        builtin(:integer) ~> 1..47
    end

    test "could be usable as any integer subtype" do
      assert {:maybe, [%Message{type: builtin(:integer), target: builtin(:neg_integer)}]} =
        builtin(:integer) ~> builtin(:neg_integer)
      assert {:maybe, [%Message{type: builtin(:integer), target: builtin(:pos_integer)}]} =
        builtin(:integer) ~> builtin(:pos_integer)
      assert {:maybe, [%Message{type: builtin(:integer), target: builtin(:non_neg_integer)}]} =
        builtin(:integer) ~> builtin(:non_neg_integer)
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([builtin(:neg_integer), builtin(:pos_integer), builtin(:non_neg_integer),
          builtin(:integer), -47, 0, 47, -10..10]),
        fn target ->
          assert {:error, %Message{type: builtin(:integer), target: ^target}} =
              (builtin(:integer) ~> target)
        end)
    end
  end

  describe "float" do
    test "is usable as self and any" do
      assert :ok = builtin(:float) ~> builtin(:float)
      assert :ok = builtin(:float) ~> builtin(:any)
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([builtin(:float)]),
        fn target ->
          assert {:error, %Message{type: builtin(:float), target: ^target}} =
              (builtin(:float) ~> target)
        end)
    end
  end

  describe "atom" do
    test "is usable as self and any" do
      assert :ok = builtin(:atom) ~> builtin(:atom)
      assert :ok = builtin(:atom) ~> builtin(:any)
    end

    test "might be usable as an atom literal" do
      assert {:maybe, [%Message{type: builtin(:atom), target: :foo}]} =
        builtin(:atom) ~> :foo
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([builtin(:atom), :foo]),
        fn target ->
          assert {:error, %Message{type: builtin(:atom), target: ^target}} =
              (builtin(:atom) ~> target)
        end)
    end
  end

  describe "reference" do
    test "is usable as self and any" do
      assert :ok = builtin(:reference) ~> builtin(:reference)
      assert :ok = builtin(:reference) ~> builtin(:any)
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([builtin(:reference)]),
        fn target ->
          assert {:error, %Message{type: builtin(:reference), target: ^target}} =
              (builtin(:reference) ~> target)
        end)
    end
  end

  describe "port" do
    test "is usable as self and any" do
      assert :ok = builtin(:port) ~> builtin(:port)
      assert :ok = builtin(:port) ~> builtin(:any)
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([builtin(:port)]),
        fn target ->
          assert {:error, %Message{type: builtin(:port), target: ^target}} =
              (builtin(:port) ~> target)
        end)
    end
  end

  describe "pid" do
    test "is usable as self and any" do
      assert :ok = builtin(:pid) ~> builtin(:pid)
      assert :ok = builtin(:pid) ~> builtin(:any)
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([builtin(:pid)]),
        fn target ->
          assert {:error, %Message{type: builtin(:pid), target: ^target}} =
              (builtin(:pid) ~> target)
        end)
    end
  end

  describe "any" do
    test "maybe can be used as anything" do
      Enum.each(
        TypeTest.Targets.except([]),
        fn target ->
          assert {:maybe, [%Message{type: builtin(:any), target: ^target}]} =
              (builtin(:any) ~> target)
        end)
    end
  end

end
