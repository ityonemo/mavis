defmodule TypeTest.BuiltinPort.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "port is bigger than pid and smaller types" do
    assert port() > none()
    assert port() > neg_integer()
    assert port() > pos_integer()
    assert port() > non_neg_integer()
    assert port() > integer()
    assert port() > float()
    assert port() > atom()
    assert port() > reference()
    assert port() > function()
  end

  test "port is smaller than other types" do
    assert port() < pid()
    assert port() < tuple()
    assert port() < map()
    assert port() < maybe_improper_list()
    assert port() < bitstring()
    assert port() < any()
  end
end
