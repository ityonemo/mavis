defmodule TypeTest.Builtin.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.{Bitstring, Function, List, Map, Tuple}

  # types in this document are tested in type compare.

  describe "none" do
    test "is smaller than all types" do
      assert builtin(:none) < -47
      assert builtin(:none) < builtin(:neg_integer)
      assert builtin(:none) < 0
      assert builtin(:none) < 47
      assert builtin(:none) < builtin(:pos_integer)
      assert builtin(:none) < builtin(:non_neg_integer)
      assert builtin(:none) < builtin(:integer)
      assert builtin(:none) < builtin(:float)
      assert builtin(:none) < :foo
      assert builtin(:none) < builtin(:atom)
      assert builtin(:none) < builtin(:reference)
      assert builtin(:none) < function(( -> 0))
      assert builtin(:none) < builtin(:port)
      assert builtin(:none) < builtin(:pid)
      assert builtin(:none) < builtin(:tuple)
      assert builtin(:none) < builtin(:map)
      assert builtin(:none) < []
      assert builtin(:none) < builtin(:list)
      assert builtin(:none) < %Bitstring{size: 0, unit: 0}
      assert builtin(:none) < builtin(:any)
    end
  end

  describe "neg_integer" do
    test "is bigger than bottom class" do
      assert builtin(:neg_integer) > builtin(:none)
    end

    test "is bigger than that which it is a superclass of" do
    #  assert builtin(:neg_integer) > -47
      assert builtin(:neg_integer) > -50..-47
    end

    test "is smaller than the class it's a subclass of" do
      assert builtin(:neg_integer) < builtin(:integer)
    end

    test "is smaller than most other things" do
      assert builtin(:neg_integer) < 0
      assert builtin(:neg_integer) < 47
      assert builtin(:neg_integer) < builtin(:pos_integer)
      assert builtin(:neg_integer) < builtin(:float) # outside of group
      assert builtin(:neg_integer) < builtin(:any)   # top
    end
  end

  describe "pos_integer" do
    test "is bigger than bottom and integer classes" do
      assert builtin(:pos_integer) > builtin(:none)
      assert builtin(:pos_integer) > -47
      assert builtin(:pos_integer) > 0
      assert builtin(:pos_integer) > -47..47
      assert builtin(:pos_integer) > builtin(:neg_integer)
    end

    test "is bigger than that which it is a superclass of" do
      assert builtin(:pos_integer) > 47
      assert builtin(:pos_integer) > 42..47
    end

    test "is smaller than a union containing it" do
      assert builtin(:pos_integer) < builtin(:pos_integer) <|> -1
    end

    test "is smaller than the classes it's a subclass of" do
      assert builtin(:pos_integer) < builtin(:non_neg_integer)
      assert builtin(:pos_integer) < builtin(:integer)
    end

    test "is smaller than most other things" do
      assert builtin(:pos_integer) < builtin(:float) # outside of group
      assert builtin(:pos_integer) < builtin(:any)   # top
    end
  end

  describe "non_neg_integer" do
    test "is bigger than bottom and integer classes" do
      assert builtin(:non_neg_integer) > builtin(:none)
      assert builtin(:non_neg_integer) > -47
      assert builtin(:non_neg_integer) > -47..47
      assert builtin(:non_neg_integer) > builtin(:neg_integer)
    end

    test "is bigger than that which it is a superclass of" do
      assert builtin(:non_neg_integer) > 0
      assert builtin(:non_neg_integer) > 47
      assert builtin(:non_neg_integer) > 42..47
      assert builtin(:non_neg_integer) > builtin(:pos_integer)
    end

    test "is smaller than a union containing it" do
      assert builtin(:non_neg_integer) < builtin(:non_neg_integer) <|> -1
    end

    test "is smaller than the classes it's a subclass of" do
      assert builtin(:non_neg_integer) < builtin(:integer)
    end

    test "is smaller than most other things" do
      assert builtin(:non_neg_integer) < builtin(:float) # outside of group
      assert builtin(:non_neg_integer) < builtin(:any)   # top
    end
  end

  describe "integer" do
    test "is bigger than bottom" do
      assert builtin(:integer) > builtin(:none)
    end

    test "is bigger than that which it is a superclass of" do
      assert builtin(:integer) > -47
      assert builtin(:integer) > -47..47
      assert builtin(:integer) > builtin(:neg_integer)
      assert builtin(:integer) > 0
      assert builtin(:integer) > 47
      assert builtin(:integer) > 42..47
      assert builtin(:integer) > builtin(:pos_integer)
    end

    test "is smaller than most other things" do
      assert builtin(:integer) < builtin(:float) # outside of group
      assert builtin(:integer) < builtin(:any)   # top
    end
  end

  describe "float" do
    test "is bigger than bottom and integer" do
      assert builtin(:float) > builtin(:none)    # bottom
      assert builtin(:float) > builtin(:integer) # outside of group
    end

    test "is smaller than a union containing it" do
      assert builtin(:float) < builtin(:float) <|> 0
    end

    test "is smaller than most other things" do
      assert builtin(:float) < builtin(:atom)      # outside of group
      assert builtin(:float) < builtin(:any)       # top
    end
  end

  describe "node" do
    test "is bigger than bottom and float" do
      assert builtin(:node) > builtin(:none)  # bottom
      assert builtin(:node) > builtin(:float) # outside of group
    end

    test "is bigger than that which it is a superclass of" do
      assert builtin(:node) > :nonode@nohost
    end

    test "is smaller than a union containing it" do
      assert builtin(:node) < builtin(:node) <|> builtin(:integer)
    end

    test "is smaller than atom, reference and top" do
      assert builtin(:node) < builtin(:atom)
      assert builtin(:node) < builtin(:reference) # outside of group
      assert builtin(:node) < builtin(:any)       # top
    end
  end

  describe "module" do
    test "is bigger than bottom and float" do
      assert builtin(:module) > builtin(:none)  # bottom
      assert builtin(:module) > builtin(:float) # outside of group
    end

    test "is bigger than that which it is a superclass of" do
      assert builtin(:module) > :nonode@nohost
    end

    test "is smaller than a union containing it" do
      assert builtin(:module) < builtin(:module) <|> builtin(:integer)
    end

    test "is smaller than atom, reference and top" do
      assert builtin(:module) < builtin(:atom)
      assert builtin(:module) < builtin(:reference) # outside of group
      assert builtin(:module) < builtin(:any)       # top
    end
  end

  describe "atom" do
    test "is bigger than bottom and float" do
      assert builtin(:atom) > builtin(:none)  # bottom
      assert builtin(:atom) > builtin(:float) # outside of group
    end

    test "is bigger than that which it is a superclass of" do
      assert builtin(:atom) > :foo
      assert builtin(:atom) > builtin(:node)
      assert builtin(:atom) > builtin(:module)
    end

    test "is smaller than a union containing it" do
      assert builtin(:atom) < builtin(:atom) <|> builtin(:integer)
    end

    test "is smaller than reference and top" do
      assert builtin(:atom) < builtin(:reference) # outside of group
      assert builtin(:atom) < builtin(:any)       # top
    end
  end

  describe "reference" do
    test "is bigger than bottom and atom" do
      assert builtin(:reference) > builtin(:none) # bottom
      assert builtin(:reference) > builtin(:atom) # outside of group
    end

    test "is smaller than a union containing it" do
      assert builtin(:reference) < builtin(:reference) <|> builtin(:integer)
    end

    test "is smaller than port and top" do
      assert builtin(:reference) < builtin(:port) # outside of group
      assert builtin(:reference) < builtin(:any)  # top
    end
  end

  describe "port" do
    test "is bigger than bottom and reference" do
      assert builtin(:port) > builtin(:none)      # bottom
      assert builtin(:port) > builtin(:reference) # outside of group
    end

    test "is smaller than a union containing it" do
      assert builtin(:port) < builtin(:port) <|> builtin(:integer)
    end

    test "is smaller than pid and top" do
      assert builtin(:port) < builtin(:pid) # outside of group
      assert builtin(:port) < builtin(:any) # top
    end
  end

  describe "pid" do
    test "is bigger than bottom and reference" do
      assert builtin(:pid) > builtin(:none)      # bottom
      assert builtin(:pid) > builtin(:port) # outside of group
    end

    test "is smaller than a union containing it" do
      assert builtin(:pid) < builtin(:pid) <|> builtin(:integer)
    end

    test "is smaller than tuple and top" do
      assert builtin(:pid) < builtin(:tuple) # outside of group
      assert builtin(:pid) < builtin(:any) # top
    end
  end

  describe "any" do
    test "is bigger than all types" do
      assert builtin(:any) > builtin(:none)
      assert builtin(:any) > -47
      assert builtin(:any) > builtin(:neg_integer)
      assert builtin(:any) > 0
      assert builtin(:any) > 47
      assert builtin(:any) > builtin(:pos_integer)
      assert builtin(:any) > builtin(:non_neg_integer)
      assert builtin(:any) > builtin(:integer)
      assert builtin(:any) > builtin(:float)
      assert builtin(:any) > :foo
      assert builtin(:any) > builtin(:atom)
      assert builtin(:any) > builtin(:reference)
      assert builtin(:any) > function(( -> 0))
      assert builtin(:any) > builtin(:port)
      assert builtin(:any) > builtin(:pid)
      assert builtin(:any) > builtin(:tuple)
      assert builtin(:any) > builtin(:map)
      assert builtin(:any) > []
      assert builtin(:any) > builtin(:list)
      assert builtin(:any) > %Bitstring{size: 0, unit: 0}
    end
  end
end
