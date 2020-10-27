defmodule TypeTest.UnionTest do
  use ExUnit.Case, async: true

  @moduletag :union

  alias Type.Union

  use Type.Operators

  import Type, only: [builtin: 1]

  test "unions keep terms in reverse order" do
    assert %Union{of: [47, 0]} = Union.of(47, 0)
    assert %Union{of: [47, 0]} = Union.of(0, 47)

    assert %Union{of: [:foo, 47]} = Union.of(:foo, 47)
    assert %Union{of: [:foo, 47]} = Union.of(47, :foo)
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
      assert %Union{of: [5, 3, 1]} = Union.of(3 <|> 5, 1)
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
      assert (-1 <|> builtin(:non_neg_integer)) == (builtin(:pos_integer) <|> -1..0)
      assert (-3..-1 <|> builtin(:non_neg_integer)) == (builtin(:pos_integer) <|> -3..0)
    end
    test "collects ranges not ending in zero" do
      assert (-1 <|> builtin(:non_neg_integer)) == (builtin(:pos_integer) <|> -1..10)
      assert (-3..-1 <|> builtin(:non_neg_integer)) == (builtin(:pos_integer) <|> -3..10)
    end
  end

  describe "when collecting non_neg_integer in unions" do
    test "collects non negative integers" do
      assert builtin(:non_neg_integer) == (builtin(:non_neg_integer) <|> 0)
      assert builtin(:non_neg_integer) == (builtin(:non_neg_integer) <|> 2)
    end
    test "collects non negative ranges" do
      assert builtin(:non_neg_integer) == (builtin(:non_neg_integer) <|> 0..10)
      assert builtin(:non_neg_integer) == (builtin(:non_neg_integer) <|> 2..10)
    end
    test "collects ranges ending in zero" do
      assert (-1 <|> builtin(:non_neg_integer)) == (builtin(:non_neg_integer) <|> -1..0)
      assert (-3..-1 <|> builtin(:non_neg_integer)) == (builtin(:non_neg_integer) <|> -3..0)
    end
    test "collects ranges not ending in zero" do
      assert (-1 <|> builtin(:non_neg_integer)) == (builtin(:non_neg_integer) <|> -1..10)
      assert (-3..-1 <|> builtin(:non_neg_integer)) == (builtin(:non_neg_integer) <|> -3..10)
    end
    test "fuses with neg_integer" do
      assert builtin(:integer) == (builtin(:neg_integer) <|> builtin(:non_neg_integer))
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

  alias Type.Tuple
  @any builtin(:any)
  @anytuple %Tuple{elements: :any}

  def tuple(list), do: %Tuple{elements: list}

  describe "for the tuple type" do
    test "anytuple merges other all tuples" do
      assert @anytuple == (@anytuple <|> %Tuple{elements: []})
      assert @anytuple == (@anytuple <|> %Tuple{elements: [@any]})
      assert @anytuple == (@anytuple <|> %Tuple{elements: [:foo]} <|> %Tuple{elements: [:bar]})
    end

    test "tuples are merged if their elements can merge" do
      assert %Tuple{elements: [@any, :bar]} == (%Tuple{elements: [@any, :bar]} <|> %Tuple{elements: [:foo, :bar]})

      assert %Tuple{elements: [:bar, @any]} == (%Tuple{elements: [:bar, @any]} <|> %Tuple{elements: [:bar, :foo]})

      assert (%Tuple{elements: [:foo, @any]} <|> %Tuple{elements: [@any, :bar]}) ==
        (%Tuple{elements: [@any, :bar]} <|> %Tuple{elements: [:foo, @any]} <|> %Tuple{elements: [:foo, :bar]})

      assert %Tuple{elements: [1..2, 1..2]} == (
        %Tuple{elements: [1, 2]} <|>
        %Tuple{elements: [2, 1]} <|>
        %Tuple{elements: [1, 1]} <|>
        %Tuple{elements: [2, 2]}
      )
    end

    test "complicated tuples can be merged" do
      # This should not be able to be solved without a more complicated SAT solver.
      unless %Tuple{elements: [1..3, 1..3, 1..3]} == (
        %Tuple{elements: [1 <|> 2, 2 <|> 3, 1 <|> 3]} <|>
        %Tuple{elements: [2 <|> 3, 1 <|> 3, 1 <|> 2]} <|>
        %Tuple{elements: [1 <|> 3, 1 <|> 2, 2 <|> 3]}
      ) do
        IO.warn("this test can't be solved without a SAT solver")
      end
    end

    test "orthogonal tuples don't merge" do
      assert %Type.Union{} = (%Type.Tuple{elements: [:foo, builtin(:integer)]} <|>
                              %Type.Tuple{elements: [:bar, builtin(:float)]})
    end
  end

  alias Type.List
  describe "for the list type" do
    test "lists with the same end type get merged" do
      assert %List{type: (:foo <|> :bar)} == (%List{type: :foo} <|> %List{type: :bar})
      assert %List{type: @any} == (%List{type: @any} <|> %List{type: :bar})

      assert %List{type: (:foo <|> :bar), final: :end} ==
        (%List{type: :foo, final: :end} <|> %List{type: :bar, final: :end})
      assert %List{type: @any, final: :end} ==
        (%List{type: @any, final: :end} <|> %List{type: :bar, final: :end})
    end

    test "nonempty: true lists get merged into nonempty: true lists" do
      assert %List{type: (:foo <|> :bar), nonempty: true} ==
        (%List{type: :foo, nonempty: true} <|> %List{type: :bar, nonempty: true})
      assert %List{type: @any, nonempty: true} ==
        (%List{type: @any, nonempty: true} <|> %List{type: :bar, nonempty: true})
    end

    test "nonempty: true lists get turned into nonempty: false lists when empty is added" do
      assert %List{} = ([] <|> %List{nonempty: true})
    end

    test "nonempty: true lists get merged into nonempty: false lists" do
      assert %List{type: :foo} = (%List{type: :foo} <|> %List{type: :foo, nonempty: true})
      assert %List{type: @any} = (%List{type: @any} <|> %List{type: :foo, nonempty: true})
    end
  end

  import Type

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
        %Type{module: String, name: :t, params: [%Type.Union{of: [4, 2]}]},
        %Type.Bitstring{size: 8, unit: 16}
      ]} = remote(String.t(range)) <|> %Type.Bitstring{size: 8, unit: 16}
    end
  end
end
