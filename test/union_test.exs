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
      assert builtin(:none) = Enum.into([], %Union{})
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
      assert builtin(:neg_integer) == (builtin(:neg_integer) <|> -2)
    end
    test "collects negative ranges" do
      assert builtin(:neg_integer) == (builtin(:neg_integer) <|> -10..-2)
    end
    test "collects partially negative ranges" do
      assert (builtin(:neg_integer) <|> 0) == (builtin(:neg_integer) <|> -10..0)
      assert (builtin(:neg_integer) <|> 0..1) == (builtin(:neg_integer) <|> -10..1)
    end
  end

  describe "when collecting pos_integer in unions" do
    test "collects positive integers" do
      assert builtin(:pos_integer) == (builtin(:pos_integer) <|> 2)
    end
    test "collects positive ranges" do
      assert builtin(:pos_integer) == (builtin(:pos_integer) <|> 2..10)
    end
    test "collects zero" do
      assert builtin(:non_neg_integer) == (builtin(:pos_integer) <|> 0)
    end
    test "collects ranges with zero" do
      assert builtin(:non_neg_integer) == (builtin(:pos_integer) <|> 0..10)
    end
    test "collects ranges ending in zero" do
      assert (0 <|> builtin(:pos_integer)) == (builtin(:pos_integer) <|> 0..1)
      assert (-3..0 <|> builtin(:pos_integer)) == (builtin(:pos_integer) <|> -3..1)
    end
  end

  describe "when collecting integer in unions" do
    test "collects neg_integer" do
      assert builtin(:integer) == (builtin(:integer) <|> builtin(:neg_integer))
    end
    test "collects integers" do
      assert builtin(:integer) == (builtin(:integer) <|> -1)
    end
    test "collects non_neg_integer" do
      assert builtin(:integer) == (builtin(:integer) <|> builtin(:non_neg_integer))
    end
    test "collects pos_integer" do
      assert builtin(:integer) == (builtin(:integer) <|> builtin(:pos_integer))
    end
    test "collects ranges" do
      assert builtin(:integer) == (builtin(:integer) <|> -3..10)
    end
  end

  test "full integer fusion" do
    assert builtin(:integer) = (builtin(:neg_integer) <|> 0 <|> builtin(:pos_integer))
    assert builtin(:integer) = (builtin(:neg_integer) <|> 0..3 <|> builtin(:pos_integer))
    assert builtin(:integer) = (builtin(:neg_integer) <|> -1..3 <|> builtin(:pos_integer))
  end

  test "builtin atom collects atoms" do
    assert :foo == (:foo <|> :foo)
    assert builtin(:atom) = (builtin(:atom) <|> :foo)
    assert builtin(:atom) = (builtin(:atom) <|> :bar)
  end

  @any builtin(:any)
  @anytuple builtin(:tuple)
  @min_2_tuple tuple({...(min: 2)})

  describe "for the tuple type" do
    test "anytuple merges other all tuples" do
      assert @anytuple == (@anytuple <|> tuple({}))
      assert @anytuple == (@anytuple <|> tuple({@any}))
      assert @anytuple == (@anytuple <|> tuple({:foo}) <|> tuple({:bar}))
    end

    test "two minimum-arity tuples get merged" do
      assert @min_2_tuple = tuple({...(min: 3)}) <|> @min_2_tuple
    end

    test "a tuple that is a subtype of another tuple gets merged" do
      outer = tuple({:ok, builtin(:integer) <|> :bar, builtin(:float) <|> builtin(:integer)})
      inner = tuple({:ok, builtin(:integer), builtin(:float)})

      assert outer == outer <|> inner
    end

    test "a defined tuple merges into an minimum-arity tuple" do
      assert @min_2_tuple = tuple({:ok, builtin(:integer)}) <|> @min_2_tuple
      assert @min_2_tuple = tuple({:ok, builtin(:binary), builtin(:integer)}) <|> @min_2_tuple
    end

    test "a tuple that is identical or has one difference gets merged" do
      duple1 = tuple({:ok, builtin(:integer)})
      duple2 = tuple({:ok, builtin(:float)})
      duple3 = tuple({:error, builtin(:integer)})

      assert duple1 == duple1 <|> duple1

      assert tuple({:ok, builtin(:number)}) == duple1 <|> duple2
      assert tuple({:ok <|> :error, builtin(:integer)}) == duple1 <|> duple3

      triple1 = tuple({:ok, builtin(:integer), builtin(:float)})
      triple2 = tuple({:error, builtin(:integer), builtin(:float)})
      triple3 = tuple({:ok, builtin(:pid), builtin(:atom)})

      assert tuple({:ok <|> :error, builtin(:integer), builtin(:float)}) ==
        triple1 <|> triple2

      # if there is more than one difference it doesn't get merged.
      assert %Type.Union{} = triple1 <|> triple3
    end

    test "tuples are merged if their elements can transitively merge" do
      assert tuple({@any, :bar}) == (tuple({@any, :bar}) <|> tuple({:foo, :bar}))

      assert tuple({:bar, @any}) == (tuple({:bar, @any}) <|> tuple({:bar, :foo}))

      assert (tuple({:foo, @any}) <|> tuple({@any, :bar})) ==
        (tuple({@any, :bar}) <|> tuple({:foo, @any}) <|> tuple({:foo, :bar}))

      assert tuple({1..2, 1..2}) == (tuple({1, 2}) <|> tuple({2, 1}) <|> tuple({1, 1}) <|> tuple({2, 2}))
    end

    test "complicated tuples can be merged" do
      # This should not be able to be solved without a more complicated SAT solver.
      unless tuple({1..3, 1..3, 1..3}) == (
        tuple({1 <|> 2, 2 <|> 3, 1 <|> 3}) <|>
        tuple({2 <|> 3, 1 <|> 3, 1 <|> 2}) <|>
        tuple({1 <|> 3, 1 <|> 2, 2 <|> 3})
      ) do
        IO.warn("this test can't be solved without a SAT solver")
      end
    end

    test "orthogonal tuples don't merge" do
      assert %Type.Union{} =
        (tuple({:foo, builtin(:integer)}) <|> tuple({:bar, builtin(:float)}))
    end

    test "tuples that are too small for a minimum don't merge" do
      assert %Type.Union{} =
        (tuple({...(min: 3)}) <|> tuple({:ok, builtin(:integer)}))
    end
  end

  alias Type.List
  describe "for the list type" do
    test "lists with the same end type get merged" do
      assert list(:foo <|> :bar) == list(:foo) <|> list(:bar)
      assert list(@any) == list(@any) <|> list(:bar)

      assert %List{type: (:foo <|> :bar), final: :end} ==
        (%List{type: :foo, final: :end} <|> %List{type: :bar, final: :end})
      assert %List{type: @any, final: :end} ==
        (%List{type: @any, final: :end} <|> %List{type: :bar, final: :end})
    end

    test "nonempty: true lists get merged into nonempty: true lists" do
      assert list(:foo <|> :bar, ...) == list(:foo, ...) <|> list(:bar, ...)
      assert list(@any, ...) == list(@any, ...) <|> list(:bar, ...)
    end

    test "nonempty: true lists get turned into nonempty: false lists when empty is added" do
      assert builtin(:list) = [] <|> list(...)
    end

    test "nonempty: true lists get merged into nonempty: false lists" do
      assert list(:foo) = list(:foo) <|> list(:foo, ...)
      assert list(@any) = list(@any) <|> list(:foo, ...)
    end
  end

  import Type, only: :macros

  describe "for strings" do
    test "fixed size strings are merged into general string" do
      assert remote(String.t) == (remote(String.t) <|> remote(String.t(42)))
    end

    test "fixed size strings are merged" do
      range = 2..3
      assert remote(String.t(range)) == (remote(String.t(2)) <|> remote(String.t(3)))
      union = 2 <|> 4
      assert remote(String.t(union)) == (remote(String.t(2)) <|> remote(String.t(4)))
    end

    test "bitstrings merge strings" do
      assert builtin(:bitstring) == remote(String.t) <|> builtin(:bitstring)
      assert builtin(:binary) == remote(String.t) <|> builtin(:binary)
    end

    test "bitstrings can merge string/1 s" do
      range = 2..4
      assert %Type.Union{of: [
        %Type.Bitstring{size: 8, unit: 16},
        %Type{module: String, name: :t, params: [%Type.Union{of: [4, 2]}]}
      ]} = remote(String.t(range)) <|> %Type.Bitstring{size: 8, unit: 16}
    end
  end
end
