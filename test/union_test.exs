defmodule TypeTest.UnionTest do
  use ExUnit.Case, async: true

  @moduletag :union

  alias Type.Union

  use Type.Operators

  import Type, only: :macros

  test "unions keep terms in reverse order" do
    assert %Union{of: [47, 0]} = Type.union(47, 0)
    assert %Union{of: [47, 0]} = Type.union(0, 47)

    assert %Union{of: [:foo, 47]} = Type.union(:foo, 47)
    assert %Union{of: [:foo, 47]} = Type.union(47, :foo)
  end

  describe "unions are collectibles" do
    test "putting nothing into the union creates nonetype" do
      assert %Type{name: :none} = Enum.into([], %Union{})
    end

    test "a single element into the union returns the same type" do
      assert 1 = Enum.into([1], %Union{})
    end

    test "multiple elements in the union are dropped together" do
      assert %Union{of: [3, 1]} = Enum.into([1, 3], %Union{})
    end

    test "when you send a union into collectible, it gets unwrapped" do
      assert %Union{of: [7, 5, 3, 1]} = Enum.into([%Union{of: [5, 1]}, %Union{of: [7, 3]}], %Union{})
    end

    test "you can into a unions and it will be ordered as epexected" do
      assert %Union{of: [5, 3, 1]} = Type.union(3 <|> 5, 1)
    end
  end

  describe "when collecting integers in unions" do
    test "adjacent integers are turned into ranges" do
      assert 1..2 == (2 <|> 1)
    end

    test "a preceding range is merged in" do
      assert 1..3 == (3 <|> 1..2)
    end

    test "an internal integer is merged" do
      assert 1..2 == 1 <|> 1..2
    end
  end

  describe "when collecting ranges in unions" do
    test "a preceding integer is merged in" do
      assert 1..3 == (2..3 <|> 1)
    end

    test "overlapping ranges are merged" do
      assert 1..4 == (2..4 <|> 1..3)
      assert 1..3 == (2..3 <|> 1..2)
    end

    test "adjacent ranges are merged" do
      assert 1..4 == (1..2 <|> 3..4)
    end
  end

  describe "when collecting neg_integer in unions" do
    test "collects negative integers" do
      assert neg_integer() == (neg_integer() <|> -2)
    end
    test "collects negative ranges" do
      assert neg_integer() == (neg_integer() <|> -10..-2)
    end
    test "collects partially negative ranges" do
      assert (neg_integer() <|> 0) == (neg_integer() <|> -10..0)
      assert (neg_integer() <|> 0..1) == (neg_integer() <|> -10..1)
    end
  end

  describe "when collecting pos_integer in unions" do
    test "collects positive integers" do
      assert pos_integer() == (pos_integer() <|> 2)
    end
    test "collects positive ranges" do
      assert pos_integer() == (pos_integer() <|> 2..10)
    end
    test "collects zero" do
      assert non_neg_integer() == (pos_integer() <|> 0)
    end
    test "collects ranges with zero" do
      assert non_neg_integer() == (pos_integer() <|> 0..10)
    end
    test "collects ranges ending in zero" do
      assert (0 <|> pos_integer()) == (pos_integer() <|> 0..1)
      assert (-3..0 <|> pos_integer()) == (pos_integer() <|> -3..1)
    end
  end

  describe "when collecting integer in unions" do
    test "collects neg_integer" do
      assert integer() == (integer() <|> neg_integer())
    end
    test "collects integers" do
      assert integer() == (integer() <|> -1)
    end
    test "collects non_neg_integer" do
      assert integer() == (integer() <|> non_neg_integer())
    end
    test "collects pos_integer" do
      assert integer() == (integer() <|> pos_integer())
    end
    test "collects ranges" do
      assert integer() == (integer() <|> -3..10)
    end
  end

  test "full integer fusion" do
    assert integer() = (neg_integer() <|> 0 <|> pos_integer())
    assert integer() = (neg_integer() <|> 0..3 <|> pos_integer())
    assert integer() = (neg_integer() <|> -1..3 <|> pos_integer())
  end

  test "builtin atom collects atoms" do
    assert :foo == (:foo <|> :foo)
    assert atom() = (atom() <|> :foo)
    assert atom() = (atom() <|> :bar)
  end


  @anytuple tuple()
  @min_2_tuple type({any(), any(), ...})

  describe "for the tuple type" do
    test "anytuple merges other all tuples" do
      assert @anytuple == (@anytuple <|> type({}))
      assert @anytuple == (@anytuple <|> type({any()}))
      assert @anytuple == (@anytuple <|> type({:foo}) <|> type({:bar}))
    end

    test "two minimum-arity tuples get merged" do
      assert @min_2_tuple = type({any(), any(), any(), ...}) <|> @min_2_tuple
    end

    test "a tuple that is a subtype of another tuple gets merged" do
      outer = type({:ok, integer() <|> :bar, float() <|> integer()})
      inner = type({:ok, integer(), float()})

      assert outer == outer <|> inner
    end

    test "a defined tuple merges into an minimum-arity tuple" do
      assert @min_2_tuple = type({:ok, integer()}) <|> @min_2_tuple
      assert @min_2_tuple = type({:ok, binary(), integer()}) <|> @min_2_tuple
    end

    test "a tuple that is identical or has one difference gets merged" do
      duple1 = type({:ok, integer()})
      duple2 = type({:ok, float()})
      duple3 = type({:error, integer()})

      assert duple1 == duple1 <|> duple1

      assert type({:ok, number()}) == duple1 <|> duple2
      assert type({:ok <|> :error, integer()}) == duple1 <|> duple3

      triple1 = type({:ok, integer(), float()})
      triple2 = type({:error, integer(), float()})
      triple3 = type({:ok, pid(), atom()})

      assert type({:ok <|> :error, integer(), float()}) ==
        triple1 <|> triple2

      # if there is more than one difference it doesn't get merged.
      assert %Type.Union{} = triple1 <|> triple3
    end

    test "tuples are merged if their elements can transitively merge" do
      assert type({any(), :bar}) == (type({any(), :bar}) <|> type({:foo, :bar}))

      assert type({:bar, any()}) == (type({:bar, any()}) <|> type({:bar, :foo}))

      assert (type({:foo, any()}) <|> type({any(), :bar})) ==
        (type({any(), :bar}) <|> type({:foo, any()}) <|> type({:foo, :bar}))

      assert type({1..2, 1..2}) == (type({1, 2}) <|> type({2, 1}) <|> type({1, 1}) <|> type({2, 2}))
    end

    test "complicated tuples can be merged" do
      # This should not be able to be solved without a more complicated SAT solver.
      unless type({1..3, 1..3, 1..3}) == (
        type({1 <|> 2, 2 <|> 3, 1 <|> 3}) <|>
        type({2 <|> 3, 1 <|> 3, 1 <|> 2}) <|>
        type({1 <|> 3, 1 <|> 2, 2 <|> 3})
      ) do
        IO.warn("this test can't be solved without a SAT solver")
      end
    end

    test "orthogonal tuples don't merge" do
      assert %Type.Union{} =
        (type({:foo, integer()}) <|> type({:bar, float()}))
    end

    test "tuples that are too small for a minimum don't merge" do
      assert %Type.Union{} =
        (type({any(), any(), any(), ...}) <|> type({:ok, integer()}))
    end
  end

  describe "for the list type" do
    alias Type.List
    test "you can't naively union lists" do
      assert %Type.Union{} = list(:foo) <|> list(:bar)
      assert %Type.Union{} = nonempty_list(:foo) <|> nonempty_list(:bar)
    end

    test "lists of supersets CAN be merged" do
      assert list(:foo <|> :bar) == list(:foo <|> :bar) <|> list(:bar)
      assert list(any()) == list(any()) <|> list(atom())
      assert list(atom()) == list(atom()) <|> list(:foo)
    end

    test "lists with the same end type get merged" do
      assert %List{type: any(), final: :end} ==
        (%List{type: any(), final: :end} <|> %List{type: :bar, final: :end})
    end

    test "nonempty lists get merged into nonempty lists" do
      assert nonempty_list(any()) == nonempty_list(any()) <|> nonempty_list(:bar)
    end

    test "nonempty: true lists get turned into nonempty: false lists when empty is added" do
      assert list() = [] <|> type([...])
    end

    test "nonempty: true lists get merged into nonempty: false lists" do
      assert list(:foo) = list(:foo) <|> nonempty_list(:foo)
      assert list(any()) = list(any()) <|> nonempty_list(:foo)
    end
  end

  describe "for bitstrings" do
    alias Type.Bitstring
    test "bitstrings with a smaller minsize gets unioned in" do
      assert %Bitstring{unit: 1} ==
        %Bitstring{size: 1, unit: 1} <|> %Bitstring{unit: 1}

      assert %Bitstring{unit: 8} ==
        %Bitstring{size: 16, unit: 8} <|> %Bitstring{unit: 8}

      assert %Bitstring{size: 8, unit: 8} ==
        %Bitstring{size: 16, unit: 8} <|> %Bitstring{size: 8, unit: 8}
    end

    test "the special case of a zero bitstring gets unioned in" do
      assert %Bitstring{unit: 1} ==
        %Bitstring{size: 1, unit: 1} <|> %Bitstring{}
      assert %Bitstring{unit: 8} ==
        %Bitstring{size: 8, unit: 8} <|> %Bitstring{}
    end

    test "bitstrings with divisible minsizes are unioned" do
      assert %Bitstring{unit: 4} ==
        %Bitstring{unit: 4} <|> %Bitstring{unit: 8}
    end

    test "bitstrings with incompatible units are not unioned" do
      assert %Type.Union{} = %Bitstring{unit: 8} <|> %Bitstring{unit: 9}
    end

    test "bitstrings with out of phase minsizes are not unioned" do
      assert %Type.Union{} =
        %Bitstring{size: 4, unit: 8} <|> %Bitstring{size: 8}
    end
  end

  describe "for functions" do
    test "two one-arity functions and same output are merged" do
      assert type((non_neg_integer() -> :foo)) ==
        type((pos_integer() -> :foo)) <|> type((0 -> :foo))
    end

    test "two one-arity functions and same input are merged" do
      # this is necessary in the case that there is something that
      # isn't reducible to pos_integer, for example:
      #
      #    def my_function(x) when is_integer(x) do
      #      if div(x, 2) == 0, do: :foo, else: :bar
      #    end
      #
      assert type((pos_integer() -> :foo <|> :bar)) ==
        type((pos_integer() -> :bar)) <|>
        type((pos_integer() -> :foo))
    end

    test "one-arity functions with different output are not merged" do
      assert %Type.Union{} =
        type((pos_integer() -> :bar)) <|> type((0 -> :foo))
    end

    test "two-arity functions are merged if one is the same" do
      assert type((:bar, non_neg_integer() -> :bar)) ==
        type((:bar, pos_integer() -> :bar)) <|>
        type((:bar, 0 -> :bar))
    end

    test "two-arity functions are merged one is a total subset" do
      assert type((atom(), pos_integer() -> :bar)) ==
        type((:bar, 1..10 -> :bar)) <|>
        type((atom(), pos_integer() -> :bar))
    end

    test "functions are not merged if they have different arities" do
      assert %Type.Union{} =
        type((atom() -> :bar)) <|> type((atom(), atom() -> :bar))
    end
  end

  describe "for strings" do
    test "bitstrings merge strings" do
      assert bitstring() == type(String.t) <|> bitstring()
      assert binary() == type(String.t) <|> binary()
    end
  end
end
