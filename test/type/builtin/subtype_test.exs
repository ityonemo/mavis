defmodule TypeTest.Builtin.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  describe "builtin none" do
    test "is a subtype of itself" do
      assert none() in none()
    end

    test "is not a subtype of any" do
      refute none() in any()
    end

    test "can be subtype of a union with itself" do
      assert none() in Type.union([none(), integer()], preserve_nones: true)
    end

    test "is not a subtype of all types" do
      TypeTest.Targets.except()
      |> Enum.each(fn target ->
        refute none() in target
      end)
    end
  end

  describe "builtin neg_integer" do
    test "is a subtype of itself" do
      assert neg_integer() in neg_integer()
    end

    test "is a subtype of integer and any" do
      assert neg_integer() in integer()
      assert neg_integer() in any()
    end

    test "is a subtype of unions with itself and integer" do
      assert neg_integer() in (neg_integer() <|> atom())
      assert neg_integer() in (integer() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute neg_integer() in (pid() <|> atom())
      refute neg_integer() in (pid() <|> atom())
    end

    test "is not a subtype of all types" do
      TypeTest.Targets.except([neg_integer(), integer()])
      |> Enum.each(fn target ->
        refute neg_integer() in target
      end)
    end
  end

  describe "builtin pos_integer" do
    test "is a subtype of itself" do
      assert pos_integer() in pos_integer()
    end

    test "is a subtype of integer and any" do
      assert pos_integer() in non_neg_integer()
      assert pos_integer() in integer()
      assert pos_integer() in any()
    end

    test "is a subtype of unions with itself and integer" do
      assert pos_integer() in (pos_integer() <|> atom())
      assert pos_integer() in (non_neg_integer() <|> atom())
      assert pos_integer() in (integer() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute pos_integer() in (pid() <|> atom())
      refute pos_integer() in (pid() <|> atom())
    end

    test "is not a subtype of all types" do
      TypeTest.Targets.except([pos_integer(), non_neg_integer(), integer()])
      |> Enum.each(fn target ->
        refute pos_integer() in target
      end)
    end
  end

  describe "builtin non_neg_integer" do
    test "is a subtype of itself" do
      assert non_neg_integer() in non_neg_integer()
    end

    test "is a subtype of integer and any" do
      assert non_neg_integer() in integer()
      assert non_neg_integer() in any()
    end

    test "is a subtype of unions with itself and integer" do
      assert non_neg_integer() in (non_neg_integer() <|> atom())
      assert non_neg_integer() in (integer() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute non_neg_integer() in (pid() <|> atom())
      refute non_neg_integer() in (pid() <|> atom())
    end

    test "is not a subtype of all types" do
      TypeTest.Targets.except([non_neg_integer(), integer()])
      |> Enum.each(fn target ->
        refute non_neg_integer() in target
      end)
    end
  end

  describe "builtin integer" do
    test "is a subtype of itself" do
      assert integer() in integer()
    end

    test "is a subtype of integer and any" do
      assert integer() in integer()
      assert integer() in any()
    end

    test "is a subtype of unions with itself" do
      assert integer() in (integer() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute integer() in (pid() <|> atom())
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([integer()])
      |> Enum.each(fn target ->
        refute integer() in target
      end)
    end
  end

  describe "builtin float" do
    test "is a subtype of itself and any" do
      assert float() in float()
      assert float() in any()
    end

    test "is a subtype of unions with itself" do
      assert float() in (float() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute float() in (pid() <|> atom())
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([float()])
      |> Enum.each(fn target ->
        refute float() in target
      end)
    end
  end

  describe "builtin node" do
    test "is a subtype of itself, atom, and any" do
      assert type(node()) in type(node())
      assert type(node()) in atom()
      assert type(node()) in any()
    end

    test "is a subtype of unions with itself" do
      assert type(node()) in (integer() <|> type(node()))
    end

    test "is not a subtype of orthogonal unions" do
      refute type(node()) in (pid() <|> integer())
    end
  end

  describe "builtin module" do
    test "is a subtype of itself, atom, and any" do
      assert module() in module()
      assert module() in atom()
      assert module() in any()
    end

    test "is a subtype of unions with itself" do
      assert module() in (integer() <|> module())
    end

    test "is not a subtype of orthogonal unions" do
      refute module() in (pid() <|> integer())
    end
  end

  describe "builtin atom" do
    test "is a subtype of itself and any" do
      assert atom() in atom()
      assert atom() in any()
    end

    test "is a subtype of unions with itself" do
      assert atom() in (integer() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute atom() in (pid() <|> integer())
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([atom()])
      |> Enum.each(fn target ->
        refute atom() in target
      end)
    end
  end

  describe "builtin reference" do
    test "is a subtype of itself ati aty" do
      assert reference() in reference()
      assert reference() in any()
    end

    test "is a subtype of unions with itself" do
      assert reference() in (reference() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute reference() in (pid() <|> atom())
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([reference()])
      |> Enum.each(fn target ->
        refute reference() in target
      end)
    end
  end

  describe "builtin port" do
    test "is a subtype of itself and any" do
      assert port() in port()
      assert port() in any()
    end

    test "is a subtype of unions with itself" do
      assert port() in (port() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute port() in (pid() <|> atom())
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([port()])
      |> Enum.each(fn target ->
        refute port() in target
      end)
    end
  end

  describe "builtin pid" do
    test "is a subtype of itself and any" do
      assert pid() in pid()
      assert pid() in any()
    end

    test "is a subtype of unions with itself" do
      assert pid() in (pid() <|> atom())
    end

    test "is not a subtype of orthogonal unions" do
      refute pid() in (integer() <|> atom())
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([pid()])
      |> Enum.each(fn target ->
        refute pid() in target
      end)
    end
  end

  describe "builtin any" do
    test "is a subtype of itself" do
      assert any() in any()
    end

    test "is not a subtype of all other types" do
      TypeTest.Targets.except([any()])
      |> Enum.each(fn target ->
        refute any() in target
      end)
    end
  end
end
