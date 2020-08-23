defmodule TypeTest.TupleCoercionTest do
  use ExUnit.Case, async: true

  @moduletag :tuple

  alias Type.{List, Bitstring, Tuple, Map, Function, Union}

  @any %Type{name: :any}

  import Type, only: :macros

  @any_tuple   %Tuple{elements: :any}
  @one_tuple   %Tuple{elements: [@any]}
  @two_tuple   %Tuple{elements: [@any, @any]}
  @empty_tuple %Tuple{elements: []}

  @integer     builtin(:integer)
  @pos_integer builtin(:pos_integer)
  @neg_integer builtin(:neg_integer)

  @builtin_types ~w"""
  none pid port reference
  float integer neg_integer non_neg_integer pos_integer
  atom module node
  """a

  describe "for all tuple types" do
    test "any types maybe coerce" do
      assert :type_maybe == Type.coercion(@any, @any_tuple)
      assert :type_maybe == Type.coercion(@any, @one_tuple)
      assert :type_maybe == Type.coercion(@any, @two_tuple)
      assert :type_maybe == Type.coercion(@any, @empty_tuple)
    end

    test "builtin types don't coerce" do
      for type <- @builtin_types do
        assert :type_error == Type.coercion(builtin(type), @any_tuple)
        assert :type_error == Type.coercion(builtin(type), @one_tuple)
        assert :type_error == Type.coercion(builtin(type), @two_tuple)
        assert :type_error == Type.coercion(builtin(type), @empty_tuple)
      end
    end
  end

  describe "for the any tuple type" do
    test "any tuple coerces" do
      assert :type_ok == Type.coercion(@any_tuple, @any_tuple)
    end

    test "all tuple types coerce" do
      assert :type_ok == Type.coercion(@any_tuple, @any_tuple)
      assert :type_ok == Type.coercion(@one_tuple, @any_tuple)
      assert :type_ok == Type.coercion(@two_tuple, @any_tuple)
      assert :type_ok == Type.coercion(@empty_tuple, @any_tuple)
    end
  end

  describe "for generic tuple types" do
    test "any tuple maybe coerces" do
      assert :type_maybe == Type.coercion(@any_tuple, @one_tuple)
      assert :type_maybe == Type.coercion(@any_tuple, @two_tuple)
      assert :type_maybe == Type.coercion(@any_tuple, @empty_tuple)
    end

    test "tuple lengths must match" do
      assert :type_error == Type.coercion(@one_tuple, @empty_tuple)
      assert :type_error == Type.coercion(@two_tuple, @empty_tuple)

      assert :type_error == Type.coercion(@empty_tuple, @one_tuple)
      assert :type_error == Type.coercion(@two_tuple,   @one_tuple)

      assert :type_error == Type.coercion(@empty_tuple, @two_tuple)
      assert :type_error == Type.coercion(@one_tuple,   @two_tuple)
    end

    test "for a one-tuple it's the expected match of the single element" do
      assert :type_ok    = Type.coercion(%Tuple{elements: [@pos_integer]}, %Tuple{elements: [@integer]})
      assert :type_maybe = Type.coercion(%Tuple{elements: [@integer]},     %Tuple{elements: [@pos_integer]})
      assert :type_error = Type.coercion(%Tuple{elements: [@neg_integer]}, %Tuple{elements: [@pos_integer]})
    end

    test "for a two-tuple it's the collected match of all elements" do
      # OK OK
      assert :type_ok    = Type.coercion(
        %Tuple{elements: [@pos_integer, @pos_integer]},
        %Tuple{elements: [@integer,     @integer]})

      # OK MAYBE
      assert :type_maybe = Type.coercion(
        %Tuple{elements: [@pos_integer, @integer]},
        %Tuple{elements: [@integer,     @pos_integer]})

      # OK ERROR
      assert :type_error = Type.coercion(
        %Tuple{elements: [@pos_integer, @neg_integer]},
        %Tuple{elements: [@integer,     @pos_integer]})

      # MAYBE OK
      assert :type_maybe = Type.coercion(
        %Tuple{elements: [@integer,     @pos_integer]},
        %Tuple{elements: [@pos_integer, @integer]})

      # MAYBE MAYBE
      assert :type_maybe = Type.coercion(
        %Tuple{elements: [@integer,     @integer]},
        %Tuple{elements: [@pos_integer, @pos_integer]})

      # MAYBE ERROR
      assert :type_error = Type.coercion(
        %Tuple{elements: [@integer,     @neg_integer]},
        %Tuple{elements: [@pos_integer, @pos_integer]})

      # ERROR OK
      assert :type_error = Type.coercion(
        %Tuple{elements: [@neg_integer, @pos_integer]},
        %Tuple{elements: [@pos_integer, @integer]})

      # ERROR MAYBE
      assert :type_error = Type.coercion(
        %Tuple{elements: [@neg_integer, @pos_integer]},
        %Tuple{elements: [@pos_integer, @integer]})

      # ERROR ERROR
      assert :type_error = Type.coercion(
        %Tuple{elements: [@neg_integer, @neg_integer]},
        %Tuple{elements: [@pos_integer, @pos_integer]})
    end
  end

end
