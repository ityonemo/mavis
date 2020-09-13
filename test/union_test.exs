defmodule TypeTest.UnionTest do
  use ExUnit.Case, async: true

  @moduletag :union

  alias Type.Union

  import Type, only: :macros

  @any builtin(:any)

  describe "unions are collectibles" do
    test "putting nothing into the union creates nonetype" do
      assert %Type{name: :none} = Enum.into([], %Union{})
    end

    test "a single element into the union returns the same type" do
      assert 1 = Enum.into([1], %Union{})
    end

    test "multiple elements in the union are dropped together" do
      assert %Union{of: [1, 3]} = Enum.into([1, 3], %Union{})
    end

    test "when you send a union into collectible, it gets unwrapped" do
      assert %Union{of: [1, 3, 5, 7]} = Enum.into([%Union{of: [1, 3]}, %Union{of: [5, 7]}], %Union{})
    end
  end

  describe "when collecting integer in unions" do
    test "collects neg_integer" do
      assert builtin(:integer) = Enum.into([builtin(:integer), builtin(:neg_integer)], %Union{})
    end
    test "collects integers" do
      assert builtin(:integer) = Enum.into([builtin(:integer), -2], %Union{})
    end
    test "collects non_neg_integer" do
      assert builtin(:integer) = Enum.into([builtin(:integer), builtin(:non_neg_integer)], %Union{})
    end
    test "collects pos_integer" do
      assert builtin(:integer) = Enum.into([builtin(:integer), builtin(:pos_integer)], %Union{})
    end
    test "collects ranges" do
      assert builtin(:integer) = Enum.into([builtin(:integer), -3..10], %Union{})
    end
  end

  describe "when collecting neg_integer in unions" do
    test "collects negative integers" do
      assert builtin(:neg_integer) = Enum.into([builtin(:neg_integer), -2], %Union{})
    end
    test "collects negative ranges" do
      assert builtin(:neg_integer) = Enum.into([builtin(:neg_integer), -10..-2], %Union{})
    end
    test "splits partially negative ranges" do
      assert %Union{of: [builtin(:neg_integer), 0..2]} =
        Enum.into([builtin(:neg_integer), -10..2], %Union{})
    end
    test "merges with non_neg_integer" do
      assert builtin(:integer) = Enum.into([builtin(:neg_integer), builtin(:non_neg_integer)], %Union{})
    end
  end

  describe "when collecting integers in unions" do
    test "they get merged into ranges" do
      assert -3..-2 = Enum.into([-3, -2], %Union{})
      assert -3..-1 = Enum.into([-3, -2, -1], %Union{})
    end
    test "0 gets merged with pos_integer" do
      assert builtin(:non_neg_integer) = Enum.into([0, builtin(:pos_integer)], %Union{})
    end
  end

  describe "when collecting ranges" do
    test "they get merged into overlapping ranges" do
      assert -3..6 = Enum.into([-3..3, -3..6], %Union{})
      assert -3..3 = Enum.into([-3..3, -1..1], %Union{})
      assert -3..6 = Enum.into([-3..3, 1..6], %Union{})
      assert -3..6 = Enum.into([-3..3, 3..6], %Union{})
      assert -3..6 = Enum.into([-3..3, 4..6], %Union{})
      assert %Union{of: [-3..3, 5..6]} = Enum.into([-3..3, 5..6], %Union{})
    end

    test "they merge into integers" do
      assert -3..4 = Enum.into([-3..4, 4], %Union{})
      assert -3..4 = Enum.into([-3..3, 4], %Union{})
      assert %Union{of: [-3..3, 5]} = Enum.into([-3..3, 5], %Union{})
    end

    test "they merge into non_neg_integer" do
      assert %Union{of: [-3..-1, builtin(:non_neg_integer)]} =
        Enum.into([-3..6, builtin(:non_neg_integer)], %Union{})
    end

    test "they merge into pos_integer" do
      assert %Union{of: [-3..-1, builtin(:non_neg_integer)]} =
        Enum.into([-3..3, builtin(:pos_integer)], %Union{})
      assert %Union{of: [-3..-1, builtin(:non_neg_integer)]} =
        Enum.into([-3..0, builtin(:pos_integer)], %Union{})
      assert builtin(:non_neg_integer) =
        Enum.into([0..3, builtin(:pos_integer)], %Union{})
    end
  end

  describe "when collecting non_neg_integer" do
    test "it merges zero, or any integer" do
      assert builtin(:non_neg_integer) = Enum.into(
        [builtin(:non_neg_integer), 0], %Union{})
      assert builtin(:non_neg_integer) = Enum.into(
        [builtin(:non_neg_integer), 1], %Union{})
    end

    test "it merges non negative ranges, or any integer" do
      assert builtin(:non_neg_integer) = Enum.into(
        [builtin(:non_neg_integer), 0..10], %Union{})
      assert builtin(:non_neg_integer) = Enum.into(
        [builtin(:non_neg_integer), 1..10], %Union{})
    end

    test "it merges pos_integer" do
      assert builtin(:non_neg_integer) = Enum.into(
        [builtin(:non_neg_integer), builtin(:pos_integer)], %Union{})
    end
  end

  describe "when collecting pos_integer" do
    test "or any integer" do
      assert builtin(:pos_integer) = Enum.into(
        [builtin(:pos_integer), 1], %Union{})
    end

    test "it merges positive ranges, or any integer" do
      assert builtin(:pos_integer) = Enum.into(
        [builtin(:pos_integer), 1..10], %Union{})
    end
  end

  test "integer fusion" do
    assert builtin(:integer) = Enum.into([builtin(:neg_integer), 0, builtin(:pos_integer)], %Union{})
    assert builtin(:integer) = Enum.into([builtin(:neg_integer), 0..3, builtin(:pos_integer)], %Union{})
    assert builtin(:integer) = Enum.into([builtin(:neg_integer), -1..3, builtin(:pos_integer)], %Union{})
  end

  test "builtin atom collects atoms" do
    assert builtin(:atom) = Enum.into([builtin(:atom), :foo], %Union{})
    assert builtin(:atom) = Enum.into([builtin(:atom), :bar], %Union{})
  end

  test "different atoms don't merge" do
    assert %Union{of: [:bar, :foo]} = Enum.into([:foo, :bar], %Union{})
  end

  alias Type.Tuple

  @anytuple %Tuple{elements: :any}

  def tuple(list), do: %Tuple{elements: list}

  describe "for the tuple type" do
    test "anytuple merges other all tuples" do
      assert @anytuple =
        Enum.into([@anytuple, tuple([])], %Union{})
      assert @anytuple =
        Enum.into([@anytuple, tuple([@any])], %Union{})
      assert @anytuple =
        Enum.into([@anytuple, tuple([:foo]), tuple([:bar])], %Union{})
    end

    test "tuples are merged if their elements can merge" do
      assert %Tuple{elements: [@any, :bar]} =
        Enum.into([tuple([@any, :bar]), tuple([:foo, :bar])], %Union{})
      assert %Tuple{elements: [:bar, @any]} =
        Enum.into([tuple([:bar, @any]), tuple([:bar, :foo])], %Union{})
      assert %Union{of: [
        %Tuple{elements: [:foo, @any]},
        %Tuple{elements: [@any, :bar]}]} =
        Enum.into([tuple([@any, :bar]), tuple([:foo, @any]), tuple([:foo, :bar])], %Union{})
    end
  end

  alias Type.List

  @anylist %List{type: @any}
  describe "for the list type" do
    test "lists with the same end type get merged" do
      assert %List{type: %Union{of: [:foo, :bar]}} =
        Enum.into([%List{type: :foo}, %List{type: :bar}], %Union{})
      assert %List{type: @any} =
        Enum.into([%List{type: @any}, %List{type: :bar}], %Union{})

      assert %List{type: %Union{of: [:foo, :bar]}, final: :end} =
        Enum.into([%List{type: :foo, final: :end}, %List{type: :bar, final: :end}], %Union{})
      assert %List{type: @any, final: :end} =
        Enum.into([%List{type: @any, final: :end}, %List{type: :bar, final: :end}], %Union{})
    end

    test "nonempty: true lists get merged into nonempty: true lists" do
      assert %List{type: :foo, nonempty: true} =
        Enum.into([%List{type: :foo, nonempty: true}, %List{type: :foo, nonempty: true}], %Union{})
      assert %List{type: @any, nonempty: true} =
        Enum.into([%List{type: @any, nonempty: true}, %List{type: :foo, nonempty: true}], %Union{})
    end

    test "nonempty: true lists get merged into nonempty: false lists" do
      assert %List{type: :foo} =
        Enum.into([%List{type: :foo}, %List{type: :foo, nonempty: true}], %Union{})
      assert %List{type: @any} =
        Enum.into([%List{type: @any}, %List{type: :foo, nonempty: true}], %Union{})
    end
  end

  alias Type.Function

  @anyfun %Function{params: :any, return: @any}

  describe "for function type" do
    test "all functions merge into any function" do
      assert @anyfun =
        Enum.into([@anyfun, %Function{params: [], return: 3}], %Union{})
      assert @anyfun =
        Enum.into([@anyfun, %Function{params: :any, return: 3}], %Union{})
      assert @anyfun =
        Enum.into([@anyfun, %Function{params: [:foo, :bar], return: @any}], %Union{})
    end

    test "any param eats up any type" do
      assert %Function{params: :any, return: 3} =
        Enum.into([%Function{params: :any, return: 3}, %Function{params: [], return: 3}], %Union{})
      assert %Function{params: :any, return: 3} =
        Enum.into([%Function{params: :any, return: 3}, %Function{params: [:foo, :bar], return: 3}], %Union{})
      assert %Function{params: :any, return: 1..3} =
        Enum.into([%Function{params: :any, return: 1..3}, %Function{params: [:foo, :bar], return: 3}], %Union{})
    end

    # TODO: make this pass after we generalize "subsume"
    test "any params can merge" do
      assert %Function{params: :any, return: 0..3} =
        Enum.into([%Function{params: :any, return: 0},
                   %Function{params: :any, return: 1..3}], %Union{})
    end

    test "any param stays orthogonal" do
      assert %Type.Union{of: [%Type.Function{params: :any, return: 0}, %Type.Function{params: [], return: 1..3}]} =
        Enum.into([%Function{params: :any, return: 0}, %Function{params: [], return: 1..3}], %Union{})
    end

    test "return: any gets merged" do
      assert %Function{params: [], return: @any} =
        Enum.into([%Function{params: [], return: @any}, %Function{params: [], return: 3}], %Union{})
      assert %Function{params: [:foo, :bar], return: @any} =
        Enum.into([%Function{params: [:foo, :bar], return: @any}, %Function{params: [:foo, :bar], return: 3}], %Union{})

      foofn = %Function{params: [:foo], return: @any}
      barfn = %Function{params: [:bar], return: 3}

      assert %Union{of: [foofn, barfn]} = Enum.into([foofn, barfn], %Union{})
    end

    # TODO: make this pass after we generalize "subsume"
    test "mergable returns get merged" do
      # if the params are identical, returns can be merged.
      assert %Function{params: [], return: 0..3} ==
        Enum.into([%Function{params: [], return: 0},
                   %Function{params: [], return: 1..3}], %Union{})
    end

    test "subsumable returns get merged" do
      # if the params are not identical, (even if subset), returns cannot be merged.
      f1 = %Function{params: [:foo], return: 0}
      f2 = %Function{params: [builtin(:atom)], return: 1..3}
      assert %Union{of: [f1, f2]} = Enum.into([f1, f2], %Union{})
    end

    test "mergable params get merged"

    test "subsumable params get merged" do
      assert %Function{params: [builtin(:atom)], return: 47} =
        Enum.into([%Function{params: [:foo], return: 47},
                   %Function{params: [builtin(:atom)], return: 47}], %Union{})
    end
  end
end
