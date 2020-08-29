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
end
