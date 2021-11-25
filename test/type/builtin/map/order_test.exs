defmodule TypeTest.BuiltinList.MapTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "map is bigger than map and smaller types" do
    assert map() > none()
    assert map() > neg_integer()
    assert map() > pos_integer()
    assert map() > non_neg_integer()
    assert map() > integer()
    assert map() > float()
    assert map() > atom()
    assert map() > reference()
    assert map() > function()
    assert map() > port()
    assert map() > pid()
    assert map() > tuple()
  end

  test "map is bigger than map subtypes" do
    assert map() > struct()
  end

  test "map is bigger than a map literal" do
    assert map() > Type.literal(%{"foo" => "bar"})
  end

  test "map is smaller than other types" do
    assert map() < list()
    assert map() < bitstring()
    assert map() < any()
  end
end
