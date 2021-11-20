defmodule TypeTest.BuiltinList.MaybeImproperListTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "maybe_improper_list is bigger than map and smaller types" do
    assert maybe_improper_list() > none()
    assert maybe_improper_list() > neg_integer()
    assert maybe_improper_list() > pos_integer()
    assert maybe_improper_list() > non_neg_integer()
    assert maybe_improper_list() > integer()
    assert maybe_improper_list() > float()
    assert maybe_improper_list() > atom()
    assert maybe_improper_list() > reference()
    assert maybe_improper_list() > function()
    assert maybe_improper_list() > port()
    assert maybe_improper_list() > pid()
    assert maybe_improper_list() > tuple()
    assert maybe_improper_list() > map()
  end

  test "maybe_improper_list is bigger than list and subtypes" do
    assert maybe_improper_list() > nonempty_charlist()
    assert maybe_improper_list() > charlist()
    assert maybe_improper_list() > iolist()
    assert maybe_improper_list() > nonempty_list()
    assert maybe_improper_list() > list()
  end

  test "maybe_improper_list is bigger than maybe_improper_list literals" do
    assert maybe_improper_list() > []
    assert maybe_improper_list() > [:foo]
    assert maybe_improper_list() > [:foo | :bar]
  end

  test "maybe_improper_list is smaller than other types" do
    assert maybe_improper_list() < bitstring()
    assert maybe_improper_list() < any()
  end
end
