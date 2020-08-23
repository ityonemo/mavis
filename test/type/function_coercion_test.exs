defmodule TypeTest.FunctionCoercionTest do
  use ExUnit.Case, async: true

  @moduletag :function

  alias Type.{List, Bitstring, Tuple, Map, Function, Union}

  import Type, only: :macros

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
        assert :type_error == Type.coercion(builtin(type), @basic_any)
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

    test "any parameters might coerce" do
      assert :type_maybe == Type.coercion(
        %Function{params: :any, return: @any},
        %Function{params: [@any], return: @any}
      )
    end

    test "parameters list determines coercion" do
      # empty list trivially is okay.
      assert :type_ok == Type.coercion(
        %Function{params: [], return: @integer},
        %Function{params: [], return: @any}
      )

      # checking the "into" parameters list:
      # if all are coercible, then we get type_ok
      assert :type_ok == Type.coercion(
        %Function{params: [@integer, @any], return: @any},
        %Function{params: [0, @any], return: @any})

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
end
