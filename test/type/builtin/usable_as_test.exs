defmodule TypeTest.Builtin.UsableAsTest do
  use ExUnit.Case, async: true

  @moduletag :usable_as

  import Type, only: :macros

  use Type.Operators

  alias Type.Message

  describe "none" do
    test "is not usable as any type" do
      Enum.each(TypeTest.Targets.except([]), fn target ->
        assert {:error, %Message{type: none(), target: ^target}} =
            (none() ~> target)
        end)
    end
  end

  describe "neg_integer" do
    test "is usable as self, integer and any" do
      assert :ok = neg_integer() ~> neg_integer()
      assert :ok = neg_integer() ~> integer()
      assert :ok = neg_integer() ~> any()
    end

    test "is usable as a union with self, integer and any" do
      assert :ok = neg_integer() ~> (neg_integer() <|> atom())
      assert :ok = neg_integer() ~> (integer() <|> atom())
      assert :ok = neg_integer() ~> (any() <|> atom())
    end

    test "could be usable as a negative number, partially negative range" do
      assert {:maybe, [%Message{type: neg_integer(), target: -1}]} =
        neg_integer() ~> -1
      assert {:maybe, [%Message{type: neg_integer(), target: -47..-1}]} =
        neg_integer() ~> -47..-1
      assert {:maybe, [%Message{type: neg_integer(), target: -10..10}]} =
        neg_integer() ~> -10..10
    end

    test "might be usable as a union with a range" do
      assert {:maybe, _} = neg_integer() ~> (-10..-1 <|> :pos_integer)
    end

    test "cannot be usable as a non-negative number, or positive range" do
      assert {:error, %Message{type: neg_integer(), target: 42}} =
        neg_integer() ~> 42
      assert {:error, %Message{type: neg_integer(), target: 0..42}} =
        neg_integer() ~> 0..42
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = neg_integer() ~> (pos_integer() <|> atom())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([-47, neg_integer(), integer(), 0, 47, -10..10]),
        fn target ->
          assert {:error, %Message{type: neg_integer(), target: ^target}} =
              (neg_integer() ~> target)
        end)
    end
  end

  describe "non_neg_integer" do
    test "is usable as self, integer and any" do
      assert :ok = non_neg_integer() ~> non_neg_integer()
      assert :ok = non_neg_integer() ~> integer()
      assert :ok = non_neg_integer() ~> any()
    end

    test "is usable as a union with self, integer and any" do
      assert :ok = non_neg_integer() ~> (non_neg_integer() <|> atom())
      assert :ok = non_neg_integer() ~> (integer() <|> atom())
      assert :ok = non_neg_integer() ~> (any() <|> atom())
    end

    test "could be usable as a non negative number, positive number, partially non negative range" do
      assert {:maybe, [%Message{type: non_neg_integer(), target: 0}]} =
        non_neg_integer() ~> 0
      assert {:maybe, [%Message{type: non_neg_integer(), target: 47}]} =
        non_neg_integer() ~> 47
      assert {:maybe, [%Message{type: non_neg_integer(), target: 0..47}]} =
        non_neg_integer() ~> 0..47
      assert {:maybe, [%Message{type: non_neg_integer(), target: -10..10}]} =
        non_neg_integer() ~> -10..10
      assert {:maybe, [%Message{type: non_neg_integer(), target: pos_integer()}]} =
        non_neg_integer() ~> pos_integer()
    end

    test "might be usable as a union with a range" do
      assert {:maybe, _} = non_neg_integer() ~> (1..10 <|> :neg_integer)
    end

    test "cannot be usable as a negative number, or negative range" do
      assert {:error, %Message{type: non_neg_integer(), target: -42}} =
        non_neg_integer() ~> -42
      assert {:error, %Message{type: non_neg_integer(), target: -42..-1}} =
        non_neg_integer() ~> -42..-1
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = non_neg_integer() ~> (neg_integer() <|> atom())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([non_neg_integer(), pos_integer(),
                                 integer(), 0, 47, -10..10]),
        fn target ->
          assert {:error, %Message{type: non_neg_integer(), target: ^target}} =
              (non_neg_integer() ~> target)
        end)
    end
  end

  describe "pos_integer" do
    test "is usable as self, integer and any" do
      assert :ok = pos_integer() ~> pos_integer()
      assert :ok = pos_integer() ~> non_neg_integer()
      assert :ok = pos_integer() ~> integer()
      assert :ok = pos_integer() ~> any()
    end

    test "is usable as a union with self, integer and any" do
      assert :ok = pos_integer() ~> (pos_integer() <|> atom())
      assert :ok = pos_integer() ~> (integer() <|> atom())
      assert :ok = pos_integer() ~> (any() <|> atom())
    end

    test "could be usable as a positive number, partially positive range" do
      assert {:maybe, [%Message{type: pos_integer(), target: 1}]} =
        pos_integer() ~> 1
      assert {:maybe, [%Message{type: pos_integer(), target: 1..47}]} =
        pos_integer() ~> 1..47
      assert {:maybe, [%Message{type: pos_integer(), target: -10..10}]} =
        pos_integer() ~> -10..10
    end

    test "might be usable as a union with a range" do
      assert {:maybe, _} = pos_integer() ~> (1..10 <|> :neg_integer)
    end

    test "cannot be usable as a negative number, negative range" do
      assert {:error, %Message{type: pos_integer(), target: -42}} =
        pos_integer() ~> -42
      assert {:error, %Message{type: pos_integer(), target: 0}} =
        pos_integer() ~> 0
      assert {:error, %Message{type: pos_integer(), target: -42..0}} =
        pos_integer() ~> -42..0
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = pos_integer() ~> (neg_integer() <|> atom())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([pos_integer(), non_neg_integer(),
          integer(), 0, 47, -10..10]),
        fn target ->
          assert {:error, %Message{type: pos_integer(), target: ^target}} =
              (pos_integer() ~> target)
        end)
    end
  end

  describe "integer" do
    test "is usable as self, integer and any" do
      assert :ok = integer() ~> integer()
      assert :ok = integer() ~> any()
    end

    test "is usable as a union with self and any" do
      assert :ok = integer() ~> (integer() <|> atom())
    end

    test "could be usable as a number, or range" do
      assert {:maybe, [%Message{type: integer(), target: 1}]} =
        integer() ~> 1
      assert {:maybe, [%Message{type: integer(), target: 1..47}]} =
        integer() ~> 1..47
    end

    test "could be usable as any integer subtype" do
      assert {:maybe, [%Message{type: integer(), target: neg_integer()}]} =
        integer() ~> neg_integer()
      assert {:maybe, [%Message{type: integer(), target: pos_integer()}]} =
        integer() ~> pos_integer()
      assert {:maybe, [%Message{type: integer(), target: non_neg_integer()}]} =
        integer() ~> non_neg_integer()
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = integer() ~> (float() <|> atom())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([neg_integer(), pos_integer(), non_neg_integer(),
          integer(), -47, 0, 47, -10..10]),
        fn target ->
          assert {:error, %Message{type: integer(), target: ^target}} =
              (integer() ~> target)
        end)
    end
  end

  describe "float" do
    test "is usable as self and any" do
      assert :ok = float() ~> float()
      assert :ok = float() ~> any()
    end

    test "is usable as a union with self and any" do
      assert :ok = float() ~> (float() <|> atom())
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = float() ~> (pid() <|> atom())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([float()]),
        fn target ->
          assert {:error, %Message{type: float(), target: ^target}} =
              (float() ~> target)
        end)
    end
  end

  describe "node" do
    test "is usable as self, atom, and any" do
      assert :ok = type(node()) ~> type(node())
      assert :ok = type(node()) ~> atom()
      assert :ok = type(node()) ~> any()
    end

    test "is usable as a union with self or atom" do
      assert :ok = type(node()) ~> (type(node()) <|> integer())
      assert :ok = type(node()) ~> (atom() <|> integer())
    end

    test "might be usable as an atom literal with node form" do
      assert {:maybe, [%Message{type: type(node()), target: :nonode@nohost}]} =
        type(node()) ~> :nonode@nohost
    end

    test "is not usable as an atom literal without node form" do
      assert {:error, %Message{type: type(node()), target: :foobar}} ==
        type(node()) ~> :foobar
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = type(node()) ~> (float() <|> integer())
    end
  end

  describe "module" do
    test "is usable as self, atom, and any" do
      assert :ok = module() ~> module()
      assert :ok = module() ~> atom()
      assert :ok = module() ~> any()
    end

    test "is usable as a union with self or atom" do
      assert :ok = module() ~> (module() <|> integer())
      assert :ok = module() ~> (atom() <|> integer())
    end

    test "might be usable as an atom literal that is a module" do
      assert {:maybe, [%Message{type: module(), target: Kernel}]} =
        module() ~> Kernel
    end

    # TODO :test that this message contains relevant information.
    test "is maybe usable as an atom literal that isn't a module (yet)" do
      assert {:maybe, [%Message{type: module(), target: :foobar}]} ==
        module() ~> :foobar
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = module() ~> (float() <|> integer())
    end
  end

  describe "atom" do
    test "is usable as self and any" do
      assert :ok = atom() ~> atom()
      assert :ok = atom() ~> any()
    end

    test "is usable as a union with self and any" do
      assert :ok = atom() ~> (atom() <|> integer())
    end

    test "might be usable as an atom literal" do
      assert {:maybe, [%Message{type: atom(), target: :foo}]} =
        atom() ~> :foo
    end

    test "might be usable as a node or module" do
      assert {:maybe, [%Message{type: atom(), target: type(node())}]} =
        atom() ~> type(node())
      assert {:maybe, [%Message{type: atom(), target: module()}]} =
        atom() ~> module()
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = atom() ~> (float() <|> integer())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([atom(), :foo]),
        fn target ->
          assert {:error, %Message{type: atom(), target: ^target}} =
              (atom() ~> target)
        end)
    end
  end

  describe "reference" do
    test "is usable as self and any" do
      assert :ok = reference() ~> reference()
      assert :ok = reference() ~> any()
    end

    test "is usable as a union with self and any" do
      assert :ok = reference() ~> (reference() <|> atom())
      assert :ok = reference() ~> (any() <|> atom())
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = reference() ~> (atom() <|> pid())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([reference()]),
        fn target ->
          assert {:error, %Message{type: reference(), target: ^target}} =
              (reference() ~> target)
        end)
    end
  end

  describe "port" do
    test "is usable as self and any" do
      assert :ok = port() ~> port()
      assert :ok = port() ~> any()
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = port() ~> (atom() <|> pid())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([port()]),
        fn target ->
          assert {:error, %Message{type: port(), target: ^target}} =
              (port() ~> target)
        end)
    end
  end

  describe "pid" do
    test "is usable as self and any" do
      assert :ok = pid() ~> pid()
      assert :ok = pid() ~> any()
    end

    test "is usable as a union with self and any" do
      assert :ok = pid() ~> (pid() <|> atom())
      assert :ok = pid() ~> (any() <|> atom())
    end

    test "is not usable as a union of disjoint types" do
      assert {:error, _} = pid() ~> (atom() <|> reference())
    end

    test "cannot generally be used as incompatible types" do
      Enum.each(
        TypeTest.Targets.except([pid()]),
        fn target ->
          assert {:error, %Message{type: pid(), target: ^target}} =
              (pid() ~> target)
        end)
    end
  end

  describe "any" do
    test "maybe can be used as anything" do
      Enum.each(
        TypeTest.Targets.except([]),
        fn target ->
          assert {:maybe, [%Message{type: any(), target: ^target}]} =
              (any() ~> target)
        end)
    end
  end

end
