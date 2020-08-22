defmodule Typerator.Type.FunctionCoercionTest do
  use ExUnit.Case, async: true

  @moduletag :coercion

  alias Type.{List, Bitstring, Tuple, Map, Function, Union}

  @any %Type{name: :any}
  @integer %Type{name: :integer}

  @builtin_types ~w"""
  none pid port reference
  float integer neg_integer non_neg_integer pos_integer
  atom module node
  """a

  @basic_any %Function{params: :any, return: @any}

  def bitstring(a, b), do: %Bitstring{size: a, unit: b}

  describe "for the any/any function" do
    test "builtin types don't coerce into functions" do
      for type <- @builtin_types do
        assert :type_error == Type.coercion(type, @basic_any)
      end
    end

    test "a generic function coerces" do
      assert :type_ok == Type.coercion(
        %Function{params: [], return: @any},
        @basic_any)

      assert :type_ok == Type.coercion(
        %Function{params: [@any, @any], return: @any},
        @basic_any)
    end

    test "it's also indifferent to the return type" do
      assert :type_ok == Type.coercion(
        %Function{params: :any, return: @integer},
        @basic_any
      )
    end

    test "an any/any function coerces" do
      assert :type_ok == Type.coercion(@basic_any, @basic_any)
    end
  end

  describe "when the any/type function" do
    test "the return type must match" do
      assert :type_ok == Type.coercion(
        %Function{params: [], return: %Type{name: :pos_integer}},
        %Function{params: :any, return: @integer}
      )
      assert :type_maybe == Type.coercion(
        %Function{params: [@any, @any], return: @integer},
        %Function{params: :any, return: %Type{name: :pos_integer}}
      )
      assert :type_error == Type.coercion(
        %Function{params: [], return: %Type{name: :pos_integer}},
        %Function{params: :any, return: %Type{name: :neg_integer}}
      )
    end
  end

  describe "for the type/any function" do
    test "mismatched parameters list fails to coerce" do
      assert :type_error == Type.coercion(
        %Function{params: [], return: @any},
        %Function{params: [@any], return: @any}
      )

      assert :type_error == Type.coercion(
        %Function{params: [@any], return: @any},
        %Function{params: [], return: @any}
      )

      assert :type_error == Type.coercion(
        %Function{params: [@any], return: @any},
        %Function{params: [@any, @any], return: @any}
      )
    end

    test "parameters list determines coercion" do
      # empty list trivially is okay.
      assert :type_ok == Type.coercion(
        %Function{params: [], return: @integer}
        %Function{params: [], return: @any}
      )

      # if all are coercible, then we get type_ok
      assert :type_ok == Type.coercion(
        %Function{params: [0, @any], return: @any},
        %Function{params: [@integer, @any], return: @any})

      # if even one is a maybe, then we get maybe
      assert :type_maybe == Type.coercion(
        %Function{params: [@integer, @integer], return: @any},
        %Function{params: [0, @any], return: @any})

      # if even one is an error, then we get error
      assert :type_error == Type.coercion(
        %Function{params: [@integer, @integer], return: @any},
        %Function{params: [:foo, @any], return: @any})
    end
  end

#  describe "for the basic bitstring type" do
#    test "any type maybe coerces" do
#      assert :type_maybe == Type.coercion(@any, @empty_bitstring)
#    end
#
#    test "all other bitstrings coerce" do
#      assert :type_ok = Type.coercion(bitstring(7, 2), @bitstring)
#      assert :type_ok = Type.coercion(@binary, @bitstring)
#    end
#    test "empty bitstring coerces" do
#      assert :type_ok = Type.coercion(@empty_bitstring, @bitstring)
#    end
#
#    test "other types can not coerce" do
#      target = @empty_bitstring
#      assert :type_error == Type.coercion(42, target)
#      assert :type_error == Type.coercion(0..42, target)
#      assert :type_error == Type.coercion(:foo, target)
#      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
#      assert :type_error == Type.coercion(%Map{kv: []}, target)
#      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
#    end
#  end
#
#  describe "for the basic binary type" do
#    test "bitstrings maybe coerce" do
#      assert :type_maybe == Type.coercion(@bitstring, @binary)
#    end
#
#    test "empty bitstrings coerce" do
#      assert :type_ok = Type.coercion(@empty_bitstring, @bitstring)
#    end
#
#    test "multiples of 8 for the unit will coerce" do
#      assert :type_ok == Type.coercion(bitstring(0, 16), @binary)
#      assert :type_ok == Type.coercion(bitstring(8, 32), @binary)
#    end
#
#    test "nonmultiples of 8 for the unit might coerce" do
#      assert :type_maybe == Type.coercion(bitstring(0, 4), @binary)
#      assert :type_maybe == Type.coercion(bitstring(0, 3), @binary)
#    end
#  end
#
#  describe "for generic bitstring types" do
#    test "going from small unit to big unit" do
#      assert :type_maybe == Type.coercion(bitstring(0, 3), bitstring(0, 6))
#      assert :type_maybe == Type.coercion(bitstring(5, 3), bitstring(5, 6))
#      assert :type_error == Type.coercion(bitstring(2, 3), bitstring(0, 6))
#    end
#  end

end
