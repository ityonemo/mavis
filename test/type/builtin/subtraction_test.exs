defmodule TypeTest.Builtin.SubtractionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :subtraction

  import Type, only: :macros

  describe "the subtraction from none" do
    test "of all other types is none" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == none() - target
      end)
    end
  end

  describe "the subtraction from any" do
    test "is not implemented"
  end

  describe "the subtraction from neg_integer" do
    test "of neg_integer, integer, or any is none" do
      assert none() == neg_integer() - neg_integer()
      assert none() == neg_integer() - integer()
      assert none() == neg_integer() - any()
    end

    test "of integers yields a subtraction only for negative integers" do
      assert %Type.Subtraction{base: neg_integer(), exclude: -47} ==
        neg_integer() - -47
      assert neg_integer() == neg_integer() - 47
    end

    test "of ranges trim as expected" do
      assert %Type.Subtraction{base: neg_integer(), exclude: -47..-10} ==
        neg_integer() - (-47..-10)
      assert %Type.Subtraction{base: neg_integer(), exclude: -47..-1} ==
        neg_integer() - (-47..47)
      assert %Type.Subtraction{base: neg_integer(), exclude: -1} ==
        neg_integer() - (-1..47)
      assert neg_integer() == neg_integer() - (1..47)
    end

    test "of unions works as expected" do
      assert %Type.Subtraction{
        base: neg_integer(),
        exclude: (-1 <|> (-47..-10))} ==
          neg_integer() - ((-47..-10) <|> (-1..47) <|> :foo)
    end

    test "of all other types is unaffected" do
      TypeTest.Targets.except([-47, neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert neg_integer() == neg_integer() - target
      end)
    end
  end

  describe "the subtraction from pos_integer()" do
    test "of any, integer, and pos_integer(), and non_neg_integer is itself" do
      assert none() == pos_integer() - any()
      assert none() == pos_integer() - integer()
      assert none() == pos_integer() - non_neg_integer()
      assert none() == pos_integer() - pos_integer()
    end

    test "of integers yields a subtraction only for positive integers" do
      assert %Type.Subtraction{base: pos_integer(), exclude: 47} ==
        pos_integer() - 47
      assert pos_integer() == pos_integer() - -47
    end

    test "of ranges trim as expected" do
      assert %Type.Subtraction{base: pos_integer(), exclude: 10..47} ==
        pos_integer() - (10..47)
      assert %Type.Subtraction{base: pos_integer(), exclude: 1..47} ==
        pos_integer() - (1..47)
      assert %Type.Subtraction{base: pos_integer(), exclude: 1} ==
        pos_integer() - (-47..1)
      assert pos_integer() == pos_integer() - (-47..-1)
    end

    test "of unions works as expected" do
      assert %Type.Subtraction{
        base: pos_integer(),
        exclude: (1 <|> (10..47))} ==
          pos_integer() - ((10..47) <|> (-47..1) <|> :foo)
    end

    test "of all other types is unaffected" do
      TypeTest.Targets.except([47, pos_integer(), non_neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert pos_integer() == pos_integer() - target
      end)
    end
  end

  describe "the subtraction from non_neg_integer" do
    test "of any, integer, and non_neg_integer is none" do
      assert none() == non_neg_integer() - any()
      assert none() == non_neg_integer() - integer()
      assert none() == non_neg_integer() - non_neg_integer()
    end

    test "of pos_integer() is 0" do
      assert 0 == non_neg_integer() - pos_integer()
    end

    test "of integers yields the integer only for negative integers" do
      assert %Type.Subtraction{base: non_neg_integer(), exclude: 47} ==
        non_neg_integer() - 47
      assert pos_integer() == non_neg_integer() - 0
      assert non_neg_integer() == non_neg_integer() - -47
    end

    test "of ranges trim as expected" do
      assert %Type.Subtraction{base: non_neg_integer(), exclude: 10..47} ==
        non_neg_integer() - (10..47)
      assert %Type.Subtraction{base: non_neg_integer(), exclude: 1..47} ==
        non_neg_integer() - (1..47)
      assert %Type.Subtraction{base: pos_integer(), exclude: 1} ==
        non_neg_integer() - (-47..1)

      assert pos_integer() == non_neg_integer() - (-47..0)
      assert non_neg_integer() == non_neg_integer() - (-47..-1)
    end

    test "of unions works as expected" do
      assert %Type.Subtraction{
        base: pos_integer(),
        exclude: (1 <|> 10..47)} ==
          non_neg_integer() - (10..47 <|> -47..1 <|> :foo)

      assert %Type.Subtraction{
        base: pos_integer(),
        exclude: 10..47} ==
          non_neg_integer() - (10..47 <|> -47..0 <|> :foo)
    end

    test "of all other types is unchanged" do
      TypeTest.Targets.except([0, 47, pos_integer(), non_neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert non_neg_integer() == non_neg_integer() - target
      end)
    end
  end

  describe "the subtraction from integer" do
    test "of any, integer is none" do
      assert none() == integer() - any()
      assert none() == integer() - integer()
    end

    test "of integer subtypes is as expected" do
      assert non_neg_integer() == integer() - neg_integer()
      assert neg_integer() <|> pos_integer() == integer() - 0
      assert 0 <|> neg_integer() == integer() - pos_integer()
    end

    test "of non-spanning ranges is as expected" do
      assert %Type.Subtraction{
        base: integer(),
        exclude: 1..47
      } == integer() - (1..47)
    end

    test "of spanning ranges can get strange" do
      assert %Type.Subtraction{
        base: neg_integer() <|> pos_integer(),
        exclude: -47..-1 <|> 1..47
      } == integer() - (-47..47)
    end

    test "of all other types is unchanged" do
      TypeTest.Targets.except([-47, 0, 47, neg_integer(), pos_integer(), non_neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert integer() == integer() - target
      end)
    end
  end

  describe "the subtraction from float" do
    test "with any, float is none" do
      assert none() == float() - any()
      assert none() == float() - float()
    end

    test "with single float values causes subtraction" do
      assert %Type.Subtraction{
        base: float(),
        exclude: 47.0
      } == float() - 47.0
    end

    test "with unions works as expected" do
      assert none() == float() - (float() <|> 15..16)
      assert float() == float() - (:foo <|> pid())

      assert %Type.Subtraction{
        base: float(),
        exclude: 47.0
      } == float() - (47.0 <|> :foo)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([float(), 47.0])
      |> Enum.each(fn target ->
        assert none() == float() <~> target
      end)
    end
  end

  describe "the subtraction from module" do
    test "of any, atom, and itself is none" do
      assert none() == module() - any()
      assert none() == module() - atom()
      assert none() == module() - module()
    end

    test "of an atom that is not a module is no change" do
      assert %Type.Subtraction{
        base: module(),
        exclude: Kernel
      } == module() - Kernel

      assert module() == module() - :foobar
    end
  end

  describe "the subtraction from node" do
    test "of any, atom, and itself is none" do
      assert none() == type(node()) - any()
      assert none() == type(node()) - atom()
      assert none() == type(node()) - type(node())
    end

    test "of an atom that has node form is itself" do
      assert %Type.Subtraction{
        base: type(node()),
        exclude: :nonode@nohost
      } == type(node()) - :nonode@nohost
      assert type(node()) == type(node()) - :foobar
    end
  end

  describe "the subtraction from atom" do
    test "of any, atom is none" do
      assert none() == atom() - any()
      assert none() == atom() - atom()
    end

    test "of an actual atom is the atom" do
      assert %Type.Subtraction{
        base: atom(),
        exclude: :foo
      } == atom() - :foo
    end

    test "of an atom subtypes is the correct subtraction" do
      assert %Type.Subtraction{
        base: atom(),
        exclude: module()
      } == atom() - module()

      assert %Type.Subtraction{
        base: atom(),
        exclude: type(node())
      } == atom() - type(node())
    end

    test "of unions works as expected" do
      assert %Type.Subtraction{
        base: atom(),
        exclude: :foo
      } == atom() - (float() <|> :foo <|> 10..12)
      assert atom() == atom() - (integer() <|> pid())
    end

    test "of all other types is unchanged" do
      TypeTest.Targets.except([:foo, atom()])
      |> Enum.each(fn target ->
        assert atom() == atom() - target
      end)
    end
  end

  describe "the subtraction from reference" do
    test "of any, reference is none" do
      assert none() == reference() - any()
      assert none() == reference() - reference()
    end

    test "of unions works as expected" do
      assert none() == reference() - (reference() <|> :foo <|> 10..12)
      assert reference() == reference() - (integer() <|> pid())
    end

    test "of all other types is unchanged" do
      TypeTest.Targets.except([reference()])
      |> Enum.each(fn target ->
        assert reference() == reference() - target
      end)
    end
  end

  describe "the subtraction from port" do
    test "of any, port is none" do
      assert none() == port() - any()
      assert none() == port() - port()
    end

    test "of unions works as expected" do
      assert none() == port() - (port() <|> :foo <|> 10..12)
      assert port() == port() - (integer() <|> pid())
    end

    test "of all other types is none" do
      TypeTest.Targets.except([port()])
      |> Enum.each(fn target ->
        assert port() == port() - target
      end)
    end
  end

  describe "the subtraction from pid" do
    test "of any, pid is none" do
      assert none() == pid() - any()
      assert none() == pid() - pid()
    end

    test "of unions works as expected" do
      assert none() == pid() - (pid() <|> :foo <|> 10..12)
      assert pid() == pid() - (integer() <|> port())
    end

    test "of all other types is unchanged" do
      TypeTest.Targets.except([pid()])
      |> Enum.each(fn target ->
        assert pid() == pid() - target
      end)
    end
  end

end
