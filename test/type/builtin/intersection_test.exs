defmodule TypeTest.Builtin.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  describe "the intersection of none" do
    test "with all other types is none" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert none() == none() <~> target
      end)
    end
  end

  describe "the intersection of any" do
    test "with all other types is itself" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert target == any() <~> target
      end)
    end
  end

  describe "the intersection of neg_integer" do
    test "with any, integer, and neg_integer is itself" do
      assert neg_integer() == neg_integer() <~> any()
      assert neg_integer() == neg_integer() <~> integer()
      assert neg_integer() == neg_integer() <~> neg_integer()
    end

    test "with integers yields the integer only for negative integers" do
      assert -47 == neg_integer() <~> -47
      assert none() == neg_integer() <~> 47
    end

    test "with ranges trim as expected" do
      assert -47..-1        == neg_integer() <~> -47..-1
      assert -47..-1        == neg_integer() <~> -47..47
      assert -1             == neg_integer() <~> -1..47
      assert none() == neg_integer() <~> 1..47
    end

    test "with unions works as expected" do
      assert -10..-1 == neg_integer() <~> (-10..10 <|> 15..16)
      assert none() == neg_integer() <~> (1..10 <|> 12..16)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([-47, neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert none() == neg_integer() <~> target
      end)
    end
  end

  describe "the intersection of pos_integer" do
    test "with any, integer, and pos_integer, and non_neg_integer is itself" do
      assert pos_integer() == pos_integer() <~> any()
      assert pos_integer() == pos_integer() <~> integer()
      assert pos_integer() == pos_integer() <~> non_neg_integer()
      assert pos_integer() == pos_integer() <~> pos_integer()
    end

    test "with integers yields the integer only for negative integers" do
      assert 47 == pos_integer() <~> 47
      assert none() == pos_integer() <~> -47
    end

    test "with ranges trim as expected" do
      assert 1..47          == pos_integer() <~> 1..47
      assert 1..47          == pos_integer() <~> -47..47
      assert 1              == pos_integer() <~> -47..1
      assert none() == pos_integer() <~> -47..-1
    end

    test "with unions works as expected" do
      assert (1..10 <|> 15..16) == pos_integer() <~> (-10..10 <|> 15..16)
      assert none() == pos_integer() <~> (:foo <|> -42)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([47, pos_integer(), non_neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert none() == pos_integer() <~> target
      end)
    end
  end

  describe "the intersection of non_neg_integer" do
    test "with any, integer, and non_neg_integer is itself" do
      assert non_neg_integer() == non_neg_integer() <~> any()
      assert non_neg_integer() == non_neg_integer() <~> integer()
      assert non_neg_integer() == non_neg_integer() <~> non_neg_integer()
    end

    test "with pos_integer is pos_integer" do
      assert pos_integer() == non_neg_integer() <~> pos_integer()
    end

    test "with integers yields the integer only for negative integers" do
      assert 47 == non_neg_integer() <~> 47
      assert 0 == non_neg_integer() <~> 0
      assert none() == non_neg_integer() <~> -47
    end

    test "with ranges trim as expected" do
      assert 0..47          == non_neg_integer() <~> 0..47
      assert 0..47          == non_neg_integer() <~> -47..47
      assert 0              == non_neg_integer() <~> -47..0
      assert none() == non_neg_integer() <~> -47..-1
    end

    test "with unions works as expected" do
      assert (0..10 <|> 15..16) == non_neg_integer() <~> (-10..10 <|> 15..16)
      assert none() == non_neg_integer() <~> (:foo <|> -42)
    end

    test "with all other types is none" do
      TypeTest.Targets.except([0, 47, pos_integer(), non_neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert none() == non_neg_integer() <~> target
      end)
    end
  end

  describe "the intersection of integer" do
    test "with any, integer is itself" do
      assert integer() == integer() <~> any()
      assert integer() == integer() <~> integer()
    end

    test "with integer subtypes is themselves" do
      [47, -47..47, neg_integer(), pos_integer(), non_neg_integer()]
      |> Enum.each(fn type ->
        assert type == integer() <~> type
      end)
    end

    test "with unions works as expected" do
      assert (-10..10 <|> 15..16) == integer() <~> (-10..10 <|> 15..16)
      assert none() == integer() <~> (:foo <|> pid())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([-47, 0, 47, neg_integer(), pos_integer(), non_neg_integer(), integer(), -10..10])
      |> Enum.each(fn target ->
        assert none() == integer() <~> target
      end)
    end
  end

  describe "the intersection of float" do
    test "with any, float is itself" do
      assert float() == float() <~> any()
      assert float() == float() <~> float()
    end

    test "with a float literal is the literal" do
      assert 47.0 == float() <~> 47.0
    end

    test "with unions works as expected" do
      assert float() == float() <~> (float() <|> 15..16)
      assert none() == float() <~> (:foo <|> pid())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([float(), 47.0])
      |> Enum.each(fn target ->
        assert none() == float() <~> target
      end)
    end
  end

  describe "the intersection of module" do
    test "with any, atom, and itself is itself" do
      assert module() == module() <~> any()
      assert module() == module() <~> atom()
      assert module() == module() <~> module()
    end

    test "with an atom that is a module is itself" do
      assert Kernel == module() <~> Kernel
      assert none() == module() <~> :foobar
    end
  end

  describe "the intersection of node" do
    test "with any, atom, and itself is itself" do
      assert node_type() == node_type() <~> any()
      assert node_type() == node_type() <~> atom()
      assert node_type() == node_type() <~> node_type()
    end

    test "with an atom that has node form is itself" do
      assert :nonode@nohost == node_type() <~> :nonode@nohost
      assert none() == node_type() <~> :foobar
    end
  end

  describe "the intersection of atom" do
    test "with any, atom is itself" do
      assert atom() == atom() <~> any()
      assert atom() == atom() <~> atom()
    end

    test "with an actual atom is the atom" do
      assert :foo == atom() <~> :foo
    end

    test "with unions works as expected" do
      assert :foo == atom() <~> (float() <|> :foo <|> 10..12)
      assert none() == atom() <~> (integer() <|> pid())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([:foo, atom()])
      |> Enum.each(fn target ->
        assert none() == atom() <~> target
      end)
    end
  end

  describe "the intersection of reference" do
    test "with any, reference is itself" do
      assert reference() == reference() <~> any()
      assert reference() == reference() <~> reference()
    end

    test "with unions works as expected" do
      assert reference() == reference() <~> (reference() <|> :foo <|> 10..12)
      assert none() == reference() <~> (integer() <|> pid())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([reference()])
      |> Enum.each(fn target ->
        assert none() == reference() <~> target
      end)
    end
  end

  describe "the intersection of port" do
    test "with any, port is itself" do
      assert port() == port() <~> any()
      assert port() == port() <~> port()
    end

    test "with unions works as expected" do
      assert port() == port() <~> (port() <|> :foo <|> 10..12)
      assert none() == port() <~> (integer() <|> pid())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([port()])
      |> Enum.each(fn target ->
        assert none() == port() <~> target
      end)
    end
  end

  describe "the intersection of pid" do
    test "with any, pid is itself" do
      assert pid() == pid() <~> any()
      assert pid() == pid() <~> pid()
    end

    test "with unions works as expected" do
      assert pid() == pid() <~> (pid() <|> :foo <|> 10..12)
      assert none() == pid() <~> (integer() <|> port())
    end

    test "with all other types is none" do
      TypeTest.Targets.except([pid()])
      |> Enum.each(fn target ->
        assert none() == pid() <~> target
      end)
    end
  end
end
