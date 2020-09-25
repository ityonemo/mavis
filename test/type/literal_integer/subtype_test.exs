defmodule TypeTest.LiteralInteger.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  describe "a literal negative number" do
    test "is a subtype of itself" do
      assert -47 in -47
    end

    test "is a subtype of integer and any builtins" do
      assert -47 in builtin(:neg_integer)
      assert -47 in builtin(:integer)
      assert -47 in builtin(:any)
    end

    test "is a subtype of an inclusive range" do
      assert -47 in -47..0
      assert -47 in -50..-40
      assert -47 in -100..-47
    end

    test "is not a subtype of other numbers" do
      refute -47 in -42
    end

    test "is not a subtype of exclusive ranges" do
      refute -47 in -42..0
    end

    test "is not a subtype of wrong integer classes" do
      refute -47 in builtin(:pos_integer)
      refute -47 in builtin(:non_neg_integer)
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([-47, builtin(:integer), builtin(:neg_integer)])
      |> Enum.each(fn target ->
        refute -47 in target
      end)
    end
  end

  describe "zero" do
    test "is a subtype of non_neg_integer" do
      assert 0 in builtin(:non_neg_integer)
    end

    test "is not a subtype of wrong integer classes" do
      refute 0 in builtin(:neg_integer)
      refute 0 in builtin(:pos_integer)
    end
  end

  describe "a positive number" do
    test "is a subtype of pos_integer and non_neg_integer" do
      assert 47 in builtin(:pos_integer)
      assert 47 in builtin(:non_neg_integer)
    end

    test "is not a subtype of wrong integer classes" do
      refute 47 in builtin(:neg_integer)
    end
  end

end
