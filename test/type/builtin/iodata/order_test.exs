defmodule TypeTest.BuiltinIodata.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "iodata is bigger than everything but bitstring" do
    assert iodata() > none()
    assert iodata() > neg_integer()
    assert iodata() > pos_integer()
    assert iodata() > non_neg_integer()
    assert iodata() > integer()
    assert iodata() > float()
    assert iodata() > atom()
    assert iodata() > reference()
    assert iodata() > port()
    assert iodata() > pid()
    assert iodata() > tuple()
    assert iodata() > map()
    assert iodata() > maybe_improper_list()
    assert iodata() > binary()
  end

  test "iodata is smaller than other types" do
    assert iodata() < bitstring()
    assert iodata() < any()
  end
end
