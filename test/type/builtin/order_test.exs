defmodule TypeTest.Builtin.OrderTest do
  use ExUnit.Case, async: true

  @moduletag :compare

  import Type, only: :macros

  use Type.Operators

  alias Type.Bitstring

  # types in this document are tested in type compare.

  describe "none" do
    test "is smaller than all types" do
      assert none() < -47
      assert none() < neg_integer()
      assert none() < 0
      assert none() < 47
      assert none() < pos_integer()
      assert none() < non_neg_integer()
      assert none() < integer()
      assert none() < float()
      assert none() < :foo
      assert none() < atom()
      assert none() < reference()
      assert none() < function(( -> 0))
      assert none() < port()
      assert none() < pid()
      assert none() < tuple()
      assert none() < map()
      assert none() < []
      assert none() < list()
      assert none() < %Bitstring{size: 0, unit: 0}
      assert none() < any()
    end
  end

  describe "neg_integer" do
    test "is bigger than bottom class" do
      assert neg_integer() > none()
    end

    test "is bigger than that which it is a superclass of" do
    #  assert neg_integer() > -47
      assert neg_integer() > -50..-47
    end

    test "is smaller than the class it's a subclass of" do
      assert neg_integer() < integer()
    end

    test "is smaller than most other things" do
      assert neg_integer() < 0
      assert neg_integer() < 47
      assert neg_integer() < pos_integer()
      assert neg_integer() < float() # outside of group
      assert neg_integer() < any()   # top
    end
  end

  describe "pos_integer" do
    test "is bigger than bottom and integer classes" do
      assert pos_integer() > none()
      assert pos_integer() > -47
      assert pos_integer() > 0
      assert pos_integer() > -47..47
      assert pos_integer() > neg_integer()
    end

    test "is bigger than that which it is a superclass of" do
      assert pos_integer() > 47
      assert pos_integer() > 42..47
    end

    test "is smaller than a union containing it" do
      assert pos_integer() < pos_integer() <|> -1
    end

    test "is smaller than the classes it's a subclass of" do
      assert pos_integer() < non_neg_integer()
      assert pos_integer() < integer()
    end

    test "is smaller than most other things" do
      assert pos_integer() < float() # outside of group
      assert pos_integer() < any()   # top
    end
  end

  describe "non_neg_integer" do
    test "is bigger than bottom and integer classes" do
      assert non_neg_integer() > none()
      assert non_neg_integer() > -47
      assert non_neg_integer() > -47..47
      assert non_neg_integer() > neg_integer()
    end

    test "is bigger than that which it is a superclass of" do
      assert non_neg_integer() > 0
      assert non_neg_integer() > 47
      assert non_neg_integer() > 42..47
      assert non_neg_integer() > pos_integer()
    end

    test "is smaller than a union containing it" do
      assert non_neg_integer() < non_neg_integer() <|> -1
    end

    test "is smaller than the classes it's a subclass of" do
      assert non_neg_integer() < integer()
    end

    test "is smaller than most other things" do
      assert non_neg_integer() < float() # outside of group
      assert non_neg_integer() < any()   # top
    end
  end

  describe "integer" do
    test "is bigger than bottom" do
      assert integer() > none()
    end

    test "is bigger than that which it is a superclass of" do
      assert integer() > -47
      assert integer() > -47..47
      assert integer() > neg_integer()
      assert integer() > 0
      assert integer() > 47
      assert integer() > 42..47
      assert integer() > pos_integer()
    end

    test "is smaller than most other things" do
      assert integer() < float() # outside of group
      assert integer() < any()   # top
    end
  end

  describe "float" do
    test "is bigger than bottom and integer" do
      assert float() > none()    # bottom
      assert float() > integer() # outside of group
    end

    test "is smaller than a union containing it" do
      assert float() < float() <|> 0
    end

    test "is smaller than most other things" do
      assert float() < atom()      # outside of group
      assert float() < any()       # top
    end
  end

  describe "node" do
    test "is bigger than bottom and float" do
      assert node_type() > none()  # bottom
      assert node_type() > float() # outside of group
    end

    test "is bigger than that which it is a superclass of" do
      assert node_type() > :nonode@nohost
    end

    test "is smaller than a union containing it" do
      assert node_type() < node_type() <|> integer()
    end

    test "is smaller than atom, reference and top" do
      assert node_type() < atom()
      assert node_type() < reference() # outside of group
      assert node_type() < any()       # top
    end
  end

  describe "module" do
    test "is bigger than bottom and float" do
      assert module() > none()  # bottom
      assert module() > float() # outside of group
    end

    test "is bigger than that which it is a superclass of" do
      assert module() > :nonode@nohost
    end

    test "is smaller than a union containing it" do
      assert module() < module() <|> integer()
    end

    test "is smaller than atom, reference and top" do
      assert module() < atom()
      assert module() < reference() # outside of group
      assert module() < any()       # top
    end
  end

  describe "atom" do
    test "is bigger than bottom and float" do
      assert atom() > none()  # bottom
      assert atom() > float() # outside of group
    end

    test "is bigger than that which it is a superclass of" do
      assert atom() > :foo
      assert atom() > node_type()
      assert atom() > module()
    end

    test "is smaller than a union containing it" do
      assert atom() < atom() <|> integer()
    end

    test "is smaller than reference and top" do
      assert atom() < reference() # outside of group
      assert atom() < any()       # top
    end
  end

  describe "reference" do
    test "is bigger than bottom and atom" do
      assert reference() > none() # bottom
      assert reference() > atom() # outside of group
    end

    test "is smaller than a union containing it" do
      assert reference() < reference() <|> integer()
    end

    test "is smaller than port and top" do
      assert reference() < port() # outside of group
      assert reference() < any()  # top
    end
  end

  describe "port" do
    test "is bigger than bottom and reference" do
      assert port() > none()      # bottom
      assert port() > reference() # outside of group
    end

    test "is smaller than a union containing it" do
      assert port() < port() <|> integer()
    end

    test "is smaller than pid and top" do
      assert port() < pid() # outside of group
      assert port() < any() # top
    end
  end

  describe "pid" do
    test "is bigger than bottom and reference" do
      assert pid() > none()      # bottom
      assert pid() > port() # outside of group
    end

    test "is smaller than a union containing it" do
      assert pid() < pid() <|> integer()
    end

    test "is smaller than tuple and top" do
      assert pid() < tuple() # outside of group
      assert pid() < any() # top
    end
  end

  describe "any" do
    test "is bigger than all types" do
      assert any() > none()
      assert any() > -47
      assert any() > neg_integer()
      assert any() > 0
      assert any() > 47
      assert any() > pos_integer()
      assert any() > non_neg_integer()
      assert any() > integer()
      assert any() > float()
      assert any() > :foo
      assert any() > atom()
      assert any() > reference()
      assert any() > function(( -> 0))
      assert any() > port()
      assert any() > pid()
      assert any() > tuple()
      assert any() > map()
      assert any() > []
      assert any() > list()
      assert any() > %Bitstring{size: 0, unit: 0}
    end
  end
end
