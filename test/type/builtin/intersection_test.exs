defmodule TypeTest.Builtin.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  describe "the intersection of none" do
    test "with all other types is none" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:none), target)
      end)
    end
  end

  describe "the intersection of any" do
    test "with all other types is itself" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        assert target == Type.intersection(builtin(:any), target)
      end)
    end
  end

  describe "the intersection of neg_integer" do
    test "with any, integer, and neg_integer is itself" do
      assert builtin(:neg_integer) == Type.intersection(builtin(:neg_integer), builtin(:any))
      assert builtin(:neg_integer) == Type.intersection(builtin(:neg_integer), builtin(:integer))
      assert builtin(:neg_integer) == Type.intersection(builtin(:neg_integer), builtin(:neg_integer))
    end

    test "with integers yields the integer only for negative integers" do
      assert -47 == Type.intersection(builtin(:neg_integer), -47)
      assert builtin(:none) == Type.intersection(builtin(:neg_integer), 47)
    end

    test "with ranges trim as expected" do
      assert -47..-1        == Type.intersection(builtin(:neg_integer), -47..-1)
      assert -47..-1        == Type.intersection(builtin(:neg_integer), -47..47)
      assert -1             == Type.intersection(builtin(:neg_integer), -1..47)
      assert builtin(:none) == Type.intersection(builtin(:neg_integer), 1..47)
    end

    test "with unions works as expected" do
      assert -10..-1 == Type.intersection(builtin(:neg_integer), (-10..10 <|> 15..16))
      assert builtin(:none) == Type.intersection(builtin(:neg_integer), (1..10 <|> 12..16))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([-47, builtin(:neg_integer), builtin(:integer), -10..10])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:neg_integer), target)
      end)
    end
  end

  describe "the intersection of pos_integer" do
    test "with any, integer, and pos_integer, and non_neg_integer is itself" do
      assert builtin(:pos_integer) == Type.intersection(builtin(:pos_integer), builtin(:any))
      assert builtin(:pos_integer) == Type.intersection(builtin(:pos_integer), builtin(:integer))
      assert builtin(:pos_integer) == Type.intersection(builtin(:pos_integer), builtin(:non_neg_integer))
      assert builtin(:pos_integer) == Type.intersection(builtin(:pos_integer), builtin(:pos_integer))
    end

    test "with integers yields the integer only for negative integers" do
      assert 47 == Type.intersection(builtin(:pos_integer), 47)
      assert builtin(:none) == Type.intersection(builtin(:pos_integer), -47)
    end

    test "with ranges trim as expected" do
      assert 1..47          == Type.intersection(builtin(:pos_integer), 1..47)
      assert 1..47          == Type.intersection(builtin(:pos_integer), -47..47)
      assert 1              == Type.intersection(builtin(:pos_integer), -47..1)
      assert builtin(:none) == Type.intersection(builtin(:pos_integer), -47..-1)
    end

    test "with unions works as expected" do
      assert (1..10 <|> 15..16) == Type.intersection(builtin(:pos_integer), (-10..10 <|> 15..16))
      assert builtin(:none) == Type.intersection(builtin(:pos_integer), (:foo <|> -42))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([47, builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer), -10..10])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:pos_integer), target)
      end)
    end
  end

  describe "the intersection of non_neg_integer" do
    test "with any, integer, and non_neg_integer is itself" do
      assert builtin(:non_neg_integer) == Type.intersection(builtin(:non_neg_integer), builtin(:any))
      assert builtin(:non_neg_integer) == Type.intersection(builtin(:non_neg_integer), builtin(:integer))
      assert builtin(:non_neg_integer) == Type.intersection(builtin(:non_neg_integer), builtin(:non_neg_integer))
    end

    test "with pos_integer is pos_integer" do
      assert builtin(:pos_integer) == Type.intersection(builtin(:non_neg_integer), builtin(:pos_integer))
    end

    test "with integers yields the integer only for negative integers" do
      assert 47 == Type.intersection(builtin(:non_neg_integer), 47)
      assert 0 == Type.intersection(builtin(:non_neg_integer), 0)
      assert builtin(:none) == Type.intersection(builtin(:non_neg_integer), -47)
    end

    test "with ranges trim as expected" do
      assert 0..47          == Type.intersection(builtin(:non_neg_integer), 0..47)
      assert 0..47          == Type.intersection(builtin(:non_neg_integer), -47..47)
      assert 0              == Type.intersection(builtin(:non_neg_integer), -47..0)
      assert builtin(:none) == Type.intersection(builtin(:non_neg_integer), -47..-1)
    end

    test "with unions works as expected" do
      assert (0..10 <|> 15..16) == Type.intersection(builtin(:non_neg_integer), (-10..10 <|> 15..16))
      assert builtin(:none) == Type.intersection(builtin(:non_neg_integer), (:foo <|> -42))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([0, 47, builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer), -10..10])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:non_neg_integer), target)
      end)
    end
  end

  describe "the intersection of integer" do
    test "with any, integer is itself" do
      assert builtin(:integer) == Type.intersection(builtin(:integer), builtin(:any))
      assert builtin(:integer) == Type.intersection(builtin(:integer), builtin(:integer))
    end

    test "with integer subtypes is themselves" do
      [47, -47..47, builtin(:neg_integer), builtin(:pos_integer), builtin(:non_neg_integer)]
      |> Enum.each(fn type ->
        assert type == Type.intersection(builtin(:integer), type)
      end)
    end

    test "with unions works as expected" do
      assert (-10..10 <|> 15..16) == Type.intersection(builtin(:integer), (-10..10 <|> 15..16))
      assert builtin(:none) == Type.intersection(builtin(:integer), (:foo <|> builtin(:pid)))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([-47, 0, 47, builtin(:neg_integer), builtin(:pos_integer), builtin(:non_neg_integer), builtin(:integer), -10..10])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:integer), target)
      end)
    end
  end

  describe "the intersection of float" do
    test "with any, float is itself" do
      assert builtin(:float) == Type.intersection(builtin(:float), builtin(:any))
      assert builtin(:float) == Type.intersection(builtin(:float), builtin(:float))
    end

    test "with unions works as expected" do
      assert builtin(:float) == Type.intersection(builtin(:float), (builtin(:float) <|> 15..16))
      assert builtin(:none) == Type.intersection(builtin(:float), (:foo <|> builtin(:pid)))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([builtin(:float)])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:float), target)
      end)
    end
  end

  describe "the intersection of atom" do
    test "with any, atom is itself" do
      assert builtin(:atom) == Type.intersection(builtin(:atom), builtin(:any))
      assert builtin(:atom) == Type.intersection(builtin(:atom), builtin(:atom))
    end

    test "with an actual atom is the atom" do
      assert :foo == Type.intersection(builtin(:atom), :foo)
    end

    test "with unions works as expected" do
      assert :foo == Type.intersection(builtin(:atom), (builtin(:float) <|> :foo <|> 10..12))
      assert builtin(:none) == Type.intersection(builtin(:atom), (builtin(:integer) <|> builtin(:pid)))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([:foo, builtin(:atom)])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:atom), target)
      end)
    end
  end

  describe "the intersection of reference" do
    test "with any, reference is itself" do
      assert builtin(:reference) == Type.intersection(builtin(:reference), builtin(:any))
      assert builtin(:reference) == Type.intersection(builtin(:reference), builtin(:reference))
    end

    test "with unions works as expected" do
      assert builtin(:reference) == Type.intersection(builtin(:reference), (builtin(:reference) <|> :foo <|> 10..12))
      assert builtin(:none) == Type.intersection(builtin(:reference), (builtin(:integer) <|> builtin(:pid)))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([builtin(:reference)])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:reference), target)
      end)
    end
  end

  describe "the intersection of port" do
    test "with any, port is itself" do
      assert builtin(:port) == Type.intersection(builtin(:port), builtin(:any))
      assert builtin(:port) == Type.intersection(builtin(:port), builtin(:port))
    end

    test "with unions works as expected" do
      assert builtin(:port) == Type.intersection(builtin(:port), (builtin(:port) <|> :foo <|> 10..12))
      assert builtin(:none) == Type.intersection(builtin(:port), (builtin(:integer) <|> builtin(:pid)))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([builtin(:port)])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:port), target)
      end)
    end
  end

  describe "the intersection of pid" do
    test "with any, pid is itself" do
      assert builtin(:pid) == Type.intersection(builtin(:pid), builtin(:any))
      assert builtin(:pid) == Type.intersection(builtin(:pid), builtin(:pid))
    end

    test "with unions works as expected" do
      assert builtin(:pid) == Type.intersection(builtin(:pid), (builtin(:pid) <|> :foo <|> 10..12))
      assert builtin(:none) == Type.intersection(builtin(:pid), (builtin(:integer) <|> builtin(:port)))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([builtin(:pid)])
      |> Enum.each(fn target ->
        assert builtin(:none) == Type.intersection(builtin(:pid), target)
      end)
    end
  end

end
