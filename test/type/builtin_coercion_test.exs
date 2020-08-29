defmodule TypeTest.BuiltinCoercionTest do
  use ExUnit.Case, async: true

  # TODO: Figure out AsBoolean rules.

  @moduletag :builtin

  alias Type.{Bitstring, Function, Map, List, Tuple}

  @any %Type{name: :any}

  import Type, only: :macros

  describe "for the any type" do
    test "all types can coerce" do
      target = @any
      assert :type_ok == Type.coercion(@any, target)
      assert :type_ok == Type.coercion(47, target)
      assert :type_ok == Type.coercion(0..47, target)
      assert :type_ok == Type.coercion(:foo, target)
      assert :type_ok == Type.coercion([], target)
      assert :type_ok == Type.coercion(%List{}, target)
      assert :type_ok == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_ok == Type.coercion(%Tuple{elements: []}, target)
      assert :type_ok == Type.coercion(%Map{kv: []}, target)
      assert :type_ok == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  @none %Type{name: :none}
  describe "for the none type" do
    test "no types can coerce" do
      target = @none
      assert :type_error == Type.coercion(@any, target)
      assert :type_error == Type.coercion(47, target)
      assert :type_error == Type.coercion(0..47, target)
      assert :type_error == Type.coercion(:foo, target)
      assert :type_error == Type.coercion([], target)
      assert :type_error == Type.coercion(%List{}, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  @singletons Enum.map(~w(pid port reference float)a, &%Type{name: &1})
  describe "for the singleton types" do
    test "self-coercion is ok" do
      for type <- @singletons do
        assert :type_ok == Type.coercion(type, type)
      end
    end

    test "any type maybe coerces" do
      for type <- @singletons do
        assert :type_maybe == Type.coercion(@any, type)
      end
    end

    test "other types cannot coerce" do
      for target <- @singletons do
        assert :type_error == Type.coercion(47, target)
        assert :type_error == Type.coercion(0..47, target)
        assert :type_error == Type.coercion(:foo, target)
        assert :type_error == Type.coercion([], target)
        assert :type_error == Type.coercion(%List{}, target)
        assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
        assert :type_error == Type.coercion(%Tuple{elements: []}, target)
        assert :type_error == Type.coercion(%Map{kv: []}, target)
        assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
      end
    end
  end

  @integer_subtypes Enum.map(
    ~w(neg_integer non_neg_integer pos_integer)a,
    &%Type{name: &1})

  describe "for the integer builtin types" do
    test "self-coercion is ok" do
      assert :type_ok == Type.coercion(builtin(:integer), builtin(:integer))
      for type <- @integer_subtypes do
        assert :type_ok == Type.coercion(type, type)
      end
    end
    
    test "all coerce into integer" do
      for type <- @integer_subtypes do
        assert :type_ok == Type.coercion(type, builtin(:integer))
      end
    end

    test "integer might coerce" do
      for type <- @integer_subtypes do
        assert :type_maybe == Type.coercion(builtin(:integer), type)
      end
    end

    test "cross-coercion is correct" do
      assert :type_error == Type.coercion(builtin(:non_neg_integer), builtin(:neg_integer))
      assert :type_error == Type.coercion(builtin(:pos_integer),     builtin(:neg_integer))
      assert :type_error == Type.coercion(builtin(:neg_integer),     builtin(:non_neg_integer))
      assert :type_ok    == Type.coercion(builtin(:pos_integer),     builtin(:non_neg_integer))
      assert :type_error == Type.coercion(builtin(:neg_integer),     builtin(:pos_integer))
      assert :type_maybe == Type.coercion(builtin(:non_neg_integer), builtin(:pos_integer))
    end

    test "single integers are correct" do
      assert :type_ok    == Type.coercion(-1, builtin(:integer))
      assert :type_ok    == Type.coercion(0,  builtin(:integer))
      assert :type_ok    == Type.coercion(1,  builtin(:integer))
      assert :type_ok    == Type.coercion(-1, builtin(:neg_integer))
      assert :type_error == Type.coercion(0,  builtin(:neg_integer))
      assert :type_error == Type.coercion(1,  builtin(:neg_integer))
      assert :type_error == Type.coercion(-1, builtin(:non_neg_integer))
      assert :type_ok    == Type.coercion(0,  builtin(:non_neg_integer))
      assert :type_ok    == Type.coercion(1,  builtin(:non_neg_integer))
      assert :type_error == Type.coercion(-1, builtin(:pos_integer))
      assert :type_error == Type.coercion(0,  builtin(:pos_integer))
      assert :type_ok    == Type.coercion(1,  builtin(:pos_integer))
    end

    test "ranges are correct" do
      assert :type_ok    == Type.coercion(-15..-1, builtin(:integer))
      assert :type_ok    == Type.coercion(-15..0,  builtin(:integer))
      assert :type_ok    == Type.coercion(-15..15, builtin(:integer))
      assert :type_ok    == Type.coercion(0..15,   builtin(:integer))
      assert :type_ok    == Type.coercion(1..15,   builtin(:integer))
      assert :type_ok    == Type.coercion(-15..-1, builtin(:neg_integer))
      assert :type_maybe == Type.coercion(-15..0,  builtin(:neg_integer))
      assert :type_maybe == Type.coercion(-15..15, builtin(:neg_integer))
      assert :type_error == Type.coercion(0..15,   builtin(:neg_integer))
      assert :type_error == Type.coercion(1..15,   builtin(:neg_integer))
      assert :type_error == Type.coercion(-15..-1, builtin(:non_neg_integer))
      assert :type_maybe == Type.coercion(-15..0,  builtin(:non_neg_integer))
      assert :type_maybe == Type.coercion(-15..15, builtin(:non_neg_integer))
      assert :type_ok    == Type.coercion(0..15,   builtin(:non_neg_integer))
      assert :type_ok    == Type.coercion(1..15,   builtin(:non_neg_integer))
      assert :type_error == Type.coercion(-15..-1, builtin(:pos_integer))
      assert :type_error == Type.coercion(-15..0,  builtin(:pos_integer))
      assert :type_maybe == Type.coercion(-15..15, builtin(:pos_integer))
      assert :type_maybe == Type.coercion(0..15,   builtin(:pos_integer))
      assert :type_ok    == Type.coercion(1..15,   builtin(:pos_integer))
    end

    test "other types cannot coerce" do
      for target <- @integer_subtypes do
        assert :type_error == Type.coercion(:foo, target)
        assert :type_error == Type.coercion([], target)
        assert :type_error == Type.coercion(%List{}, target)
        assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
        assert :type_error == Type.coercion(%Tuple{elements: []}, target)
        assert :type_error == Type.coercion(%Map{kv: []}, target)
        assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
      end
    end
  end

  describe "for the atom builtin type" do
    test "self-coercion is ok" do
      assert :type_ok == Type.coercion(builtin(:atom), builtin(:atom))
    end

    test "any type maybe coerces" do
      assert :type_maybe == Type.coercion(@any, builtin(:atom))
    end

    test "an atom literal coerces" do
      assert :type_ok == Type.coercion(:foo, builtin(:atom))
    end

    test "other types cannot coerce" do
      target = builtin(:atom)
      assert :type_error == Type.coercion(47, target)
      assert :type_error == Type.coercion(0..47, target)
      assert :type_error == Type.coercion([], target)
      assert :type_error == Type.coercion(%List{}, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  describe "for the module builtin type" do
    test "self-coercion is ok" do
      assert :type_ok == Type.coercion(builtin(:module), builtin(:module))
    end

    test "any type maybe coerces" do
      assert :type_maybe == Type.coercion(@any, builtin(:module))
    end

    test "atom type maybe coerces" do
      assert :type_maybe == Type.coercion(builtin(:atom), builtin(:module))
    end

    test "an atom literals coerce if the module is known to exist" do
      assert :type_ok    == Type.coercion(String, builtin(:module))
      assert :type_maybe == Type.coercion(:not_a_module, builtin(:module))
    end

    test "other types cannot coerce" do
      target = builtin(:atom)
      assert :type_error == Type.coercion(47, target)
      assert :type_error == Type.coercion(0..47, target)
      assert :type_error == Type.coercion([], target)
      assert :type_error == Type.coercion(%List{}, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  describe "for the node builtin type" do
    test "self-coercion is ok" do
      assert :type_ok == Type.coercion(builtin(:node), builtin(:node))
    end

    test "any type maybe coerces" do
      assert :type_maybe == Type.coercion(@any, builtin(:node))
    end

    test "atom type maybe coerces" do
      assert :type_maybe == Type.coercion(builtin(:atom), builtin(:node))
    end

    test "atom literals coerce depending on form" do
      assert :type_ok == Type.coercion(:foo@bar, builtin(:node))
      assert :type_error == Type.coercion(:foo, builtin(:node))
    end

    test "other types cannot coerce" do
      target = builtin(:node)
      assert :type_error == Type.coercion(47, target)
      assert :type_error == Type.coercion(0..47, target)
      assert :type_error == Type.coercion([], target)
      assert :type_error == Type.coercion(%List{}, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

  describe "for the iolist builtin type" do
    test "self-coercion is ok" do
      assert :type_ok == Type.coercion(builtin(:iolist), builtin(:iolist))
    end

    test "any type maybe coerces" do
      assert :type_maybe == Type.coercion(@any, builtin(:iolist))
    end

    test "simple lists coerce"

    test "empty list coerces" do
      assert :type_ok == Type.coercion([], builtin(:iolist))
    end

    test "generic list maybe coerces"

    test "other types cannot coerce" do
      target = builtin(:iolist)
      assert :type_error == Type.coercion(47, target)
      assert :type_error == Type.coercion(0..47, target)
      assert :type_error == Type.coercion(%Bitstring{size: 0, unit: 0}, target)
      assert :type_error == Type.coercion(%Tuple{elements: []}, target)
      assert :type_error == Type.coercion(%Map{kv: []}, target)
      assert :type_error == Type.coercion(%Function{params: [], return: :foo}, target)
    end
  end

end
