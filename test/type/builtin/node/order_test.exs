defmodule TypeTest.BuiltinNode.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "node is bigger than none and number types" do
    assert type(node()) > none()
    assert type(node()) > neg_integer()
    assert type(node()) > pos_integer()
    assert type(node()) > non_neg_integer()
    assert type(node()) > integer()
    assert type(node()) > float()
  end

  test "node is bigger than a node" do
    assert type(node()) > :foo@bar
  end

  test "node is smaller than module" do
    assert type(node()) < module()
  end

  test "node is smaller than atom, its parent" do
    assert type(node()) < atom()
  end

  test "node is smaller than other types" do
    assert type(node()) < reference()
    assert type(node()) < function()
    assert type(node()) < port()
    assert type(node()) < pid()
    assert type(node()) < tuple()
    assert type(node()) < map()
    assert type(node()) < maybe_improper_list()
    assert type(node()) < bitstring()
    assert type(node()) < any()
  end
end
