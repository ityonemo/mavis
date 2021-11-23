defmodule TypeTest.BuiltinMfa.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :order

  import Type, only: :macros

  use Type.Operators

  test "mfa is bigger pid types" do
    assert mfa() > none()
    assert mfa() > neg_integer()
    assert mfa() > pos_integer()
    assert mfa() > non_neg_integer()
    assert mfa() > integer()
    assert mfa() > float()
    assert mfa() > reference()
    assert mfa() > function()
    assert mfa() > port()
    assert mfa() > pid()
  end

  test "mfa is bigger than an actual mfa" do
    assert mfa() > literal({Kernel, :+, 2})
  end

  test "mfa is smaller than tuples and general tuple types" do
    assert mfa() < %Type.Tuple{elements: [], fixed: false}
    assert mfa() < %Type.Tuple{elements: [any()], fixed: false}
    assert mfa() < %Type.Tuple{elements: [any(), any()], fixed: false}
    assert mfa() < %Type.Tuple{elements: [any(), any(), any()]}
    assert mfa() < tuple()
  end

  test "mfa is smaller than other types" do
    assert mfa() < map()
    assert mfa() < maybe_improper_list()
    assert mfa() < bitstring()
    assert mfa() < any()
  end
end
