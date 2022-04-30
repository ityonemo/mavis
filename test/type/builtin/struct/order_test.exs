defmodule TypeTest.BuiltinStruct.MapTest do
  use ExUnit.Case, async: true

  @moduletag :order
  @moduletag :struct

  import Type, only: :macros

  use Type.Operators

  test "struct is bigger than struct and smaller types" do
    assert struct() > none()
    assert struct() > neg_integer()
    assert struct() > pos_integer()
    assert struct() > non_neg_integer()
    assert struct() > integer()
    assert struct() > float()
    assert struct() > atom()
    assert struct() > reference()
    assert struct() > function()
    assert struct() > port()
    assert struct() > pid()
    assert struct() > tuple()
  end

  test "struct is bigger than a struct literal" do
    assert struct() > Type.of(%Version{major: 1, minor: 0, patch: "a"})
  end

  test "struct is smaller than map" do
    assert struct() < map()
  end

  test "struct is smaller than other types" do
    assert struct() < list()
    assert struct() < bitstring()
    assert struct() < any()
  end
end
