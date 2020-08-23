defmodule TypeTest.BitstringCoercionTest do
  use ExUnit.Case, async: true

  @moduletag :bitstring

  alias Type.{List, Bitstring, Tuple, Map, Function, Union}

  @any %Type{name: :any}

  @builtin_types ~w"""
  none pid port reference
  float integer neg_integer non_neg_integer pos_integer
  atom module node
  """a

  @empty_bitstring %Bitstring{size: 0, unit: 0}
  @bitstring %Bitstring{size: 0, unit: 1}
  @binary %Bitstring{size: 0, unit: 8}

  def bitstring(a, b), do: %Bitstring{size: a, unit: b}

  describe "for the empty bitstring type" do
    test "builtin types don't coerce" do
      for type <- @builtin_types do
        assert :type_error == Type.coercion(type, @empty_bitstring)
      end
    end

    test "any other bitstring might coerce" do
      assert :type_maybe == Type.coercion(@bitstring, @empty_bitstring)
      assert :type_maybe == Type.coercion(@binary, @empty_bitstring)
    end

    test "a bitstring with nonzero size never coerces" do
      assert :type_error == Type.coercion(%Bitstring{size: 1, unit: 4}, @empty_bitstring)
    end
  end

  describe "for the basic bitstring type" do
    test "any type maybe coerces" do
      assert :type_maybe == Type.coercion(@any, @empty_bitstring)
    end

    test "all other bitstrings coerce" do
      assert :type_ok = Type.coercion(bitstring(7, 2), @bitstring)
      assert :type_ok = Type.coercion(@binary, @bitstring)
    end
    test "empty bitstring coerces" do
      assert :type_ok = Type.coercion(@empty_bitstring, @bitstring)
    end

    test "other types can not coerce" do
      target = @empty_bitstring
      assert :type_error == Type.coercion(42, target)
      assert :type_error == Type.coercion(0..42, target)
      assert :type_error == Type.coercion(:foo, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  describe "for the basic binary type" do
    test "bitstrings maybe coerce" do
      assert :type_maybe == Type.coercion(@bitstring, @binary)
    end

    test "empty bitstrings coerce" do
      assert :type_ok = Type.coercion(@empty_bitstring, @bitstring)
    end

    test "multiples of 8 for the unit will coerce" do
      assert :type_ok == Type.coercion(bitstring(0, 16), @binary)
      assert :type_ok == Type.coercion(bitstring(8, 32), @binary)
    end

    test "nonmultiples of 8 for the unit might coerce" do
      assert :type_maybe == Type.coercion(bitstring(0, 4), @binary)
      assert :type_maybe == Type.coercion(bitstring(0, 3), @binary)
    end
  end

  describe "for generic bitstring types" do
    test "going from small unit to big unit" do
      assert :type_maybe == Type.coercion(bitstring(0, 3), bitstring(0, 6))
      assert :type_maybe == Type.coercion(bitstring(5, 3), bitstring(5, 6))
      assert :type_error == Type.coercion(bitstring(2, 3), bitstring(0, 6))
    end
  end

end
