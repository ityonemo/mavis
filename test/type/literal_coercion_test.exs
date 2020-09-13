defmodule TypeTest.LiteralCoercionTest do
  use ExUnit.Case, async: true

  @moduletag :literal

  alias Type.{List, Bitstring, Tuple, Map, Function}

  @any %Type{name: :any}

  import Type, only: :macros

  describe "for the integer literal type" do
    test "any and integer types maybe coerce" do
      assert :type_maybe == Type.coercion(@any, 47)
      assert :type_maybe == Type.coercion(builtin(:integer), 47)
    end

    test "generic superanges containing the integer can coerce" do
      assert :type_ok    == Type.coercion(builtin(:neg_integer), -1)
      assert :type_error == Type.coercion(builtin(:non_neg_integer), -1)
      assert :type_error == Type.coercion(builtin(:pos_integer), -1)
      assert :type_error == Type.coercion(builtin(:neg_integer), 0)
      assert :type_ok    == Type.coercion(builtin(:non_neg_integer), 0)
      assert :type_error == Type.coercion(builtin(:pos_integer), 0)
      assert :type_error == Type.coercion(builtin(:neg_integer), 1)
      assert :type_ok    == Type.coercion(builtin(:non_neg_integer), 1)
      assert :type_ok    == Type.coercion(builtin(:pos_integer), 1)
    end

    test "only the same integer can coerce" do
      assert :type_ok    == Type.coercion(47, 47)
      assert :type_error == Type.coercion(42, 47)
    end

    test "only ranges containing the integer can coerce" do
      assert :type_maybe == Type.coercion(0..100, 47)
      assert :type_error == Type.coercion(0..42, 47)
    end

    test "other types can not coerce" do
      target = 47
      assert :type_error == Type.coercion(:foo, target)
      assert :type_error == Type.coercion([], target)
      assert :type_error == Type.coercion(%List{}, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  describe "for the range literal type" do
    test "any and integer types maybe coerce" do
      assert :type_maybe == Type.coercion(@any, 1..47)
      assert :type_maybe == Type.coercion(builtin(:integer), 1..47)
    end

    test "generic superanges containing the literal can coerce" do
      assert :type_maybe == Type.coercion(builtin(:neg_integer), -47..-1)
      assert :type_error == Type.coercion(builtin(:non_neg_integer), -47..-1)
      assert :type_error == Type.coercion(builtin(:pos_integer), -47..-1)
      assert :type_maybe == Type.coercion(builtin(:neg_integer), -47..0)
      assert :type_maybe == Type.coercion(builtin(:non_neg_integer), -47..0)
      assert :type_error == Type.coercion(builtin(:pos_integer), -47..0)
      assert :type_maybe == Type.coercion(builtin(:neg_integer), -47..47)
      assert :type_maybe == Type.coercion(builtin(:non_neg_integer), -47..47)
      assert :type_maybe == Type.coercion(builtin(:pos_integer), -47..47)
      assert :type_error == Type.coercion(builtin(:neg_integer), 0..47)
      assert :type_maybe == Type.coercion(builtin(:non_neg_integer), 0..47)
      assert :type_maybe == Type.coercion(builtin(:pos_integer), 0..47)
      assert :type_error == Type.coercion(builtin(:neg_integer), 1..47)
      assert :type_maybe == Type.coercion(builtin(:non_neg_integer), 1..47)
      assert :type_maybe == Type.coercion(builtin(:pos_integer), 1..47)
    end

    test "in-range integers can coerce" do
      assert :type_ok    == Type.coercion(46, 45..47)
      assert :type_error == Type.coercion(42, 45..47)
    end

    test "ranges coerce as expected" do
      assert :type_ok    == Type.coercion(45..47, 45..47)
      assert :type_ok    == Type.coercion(46..47, 45..47)
      assert :type_maybe == Type.coercion(44..56, 45..47)
      assert :type_maybe == Type.coercion(44..46, 45..47)
      assert :type_maybe == Type.coercion(46..56, 45..47)
      assert :type_error == Type.coercion(0..42,  45..47)
    end

    test "other types can not coerce" do
      target = 45..47
      assert :type_error == Type.coercion(:foo, target)
      assert :type_error == Type.coercion([], target)
      assert :type_error == Type.coercion(%List{}, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  describe "for the empty list literal type" do
    test "an empty list coerces itself" do
      assert :type_ok == Type.coercion([], [])
    end

    test "any and list types maybe coerce" do
      assert :type_maybe == Type.coercion(@any, [])
      assert :type_maybe == Type.coercion(%List{}, [])
    end

    test "a list type with nonempty: true does not coerce" do
      assert :type_error == Type.coercion(%List{nonempty: true}, [])
    end

    test "other types can not coerce" do
      target = []
      assert :type_error == Type.coercion(42, target)
      assert :type_error == Type.coercion(0..42, target)
      assert :type_error == Type.coercion(:foo, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  describe "for an atom literal" do
    test "an atm coerces itself" do
      assert :type_ok == Type.coercion(:foo, :foo)
    end

    test "any and list types maybe coerce" do
      assert :type_maybe == Type.coercion(@any, :foo)
      assert :type_maybe == Type.coercion(builtin(:atom), :foo)
    end


    test "other types can not coerce" do
      target = :foo
      assert :type_error == Type.coercion(42, target)
      assert :type_error == Type.coercion(0..42, target)
      assert :type_error == Type.coercion([], target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end
end
