defmodule TypeTest.ListCoercionTest do
  use ExUnit.Case, async: true

  @moduletag :list

  alias Type.{List, Bitstring, Tuple, Map, Function, Union}

  import Type, only: :macros

  @any %Type{name: :any}
  @integer %Type{name: :integer}

  @builtin_types ~w"""
  none pid port reference
  float integer neg_integer non_neg_integer pos_integer
  atom module node
  """a

  describe "for the trivial list type" do
    test "any type maybe coerces" do
      assert :type_maybe == Type.coercion(@any, %List{})
    end

    test "builtin types don't coerce" do
      for type <- @builtin_types do
        assert :type_error == Type.coercion(builtin(type), %List{})
      end
    end

    test "empty list coerces" do
      assert :type_ok == Type.coercion([], %List{})
    end

    test "other types can not coerce" do
      target = %List{}
      assert :type_error == Type.coercion(42, target)
      assert :type_error == Type.coercion(0..42, target)
      assert :type_error == Type.coercion(:foo, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  describe "for specific list types" do
    test "list of any will go into itself and maybe into anything" do
      assert :type_ok == Type.coercion(%List{type: @any}, %List{type: @any})
      assert :type_maybe == Type.coercion(%List{type: @any}, %List{type: @integer})
    end

    test "supertype, subtype, and disjoint element lists do what you expect" do
      assert :type_ok    == Type.coercion(%List{type: 47}, %List{type: @integer})
      assert :type_maybe == Type.coercion(%List{type: @integer}, %List{type: 47})
      assert :type_error == Type.coercion(%List{type: 42}, %List{type: 47})
    end

    test "a list that is obligate nonempty can coerce into a maybe empty, but not vice versa" do
      assert :type_ok    == Type.coercion(%List{type: @any, nonempty: true}, %List{type: @any, nonempty: false})
      assert :type_maybe == Type.coercion(%List{type: @any, nonempty: false}, %List{type: @any, nonempty: true})
    end
  end

end
