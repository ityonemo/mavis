defmodule TypeTest.LiteralRange.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  describe "a literal negative range" do
    test "is a subtype of itself" do
      assert -47..-1 in -47..-1
    end

    test "is a subtype of integer and any builtins" do
      assert -47..-1 in builtin(:neg_integer)
      assert -47..-1 in builtin(:integer)
      assert -47..-1 in builtin(:any)
    end

    test "is a subtype of an inclusive range" do
      assert -47..-1 in -47..0
      assert -47..-1 in -50..-0
      assert -47..-1 in -50..-1
    end

    test "is not a subtype of other ranges" do
      refute -47..-1 in -46..-2
      refute -47..-1 in -50..-2
      refute -47..-1 in -46..0
      refute -47..-1 in 1..47
    end

    test "is not a subtype of wrong integer classes" do
      refute -47..-1 in builtin(:pos_integer)
      refute -47..-1 in builtin(:non_neg_integer)
    end

    test "is a subtype of unions with ranges and integer classes" do
      assert -47..-1 in (-47..-1 <|> builtin(:atom))
      assert -47..-1 in (-50..-1 <|> builtin(:atom))
      assert -47..-1 in (builtin(:neg_integer) <|> builtin(:atom))
      assert -47..-1 in (builtin(:integer) <|> builtin(:atom))
    end

    test "is not a subtype of orthogonal types" do
      refute -47..-1 in (builtin(:pos_integer) <|> builtin(:atom))
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([builtin(:integer), builtin(:neg_integer)])
      |> Enum.each(fn target ->
        refute -47..-1 in target
      end)
    end
  end

  describe "a range ending in zero" do
    test "is a subtype of integer and any builtins" do
      assert -42..0 in builtin(:integer)
      assert -42..0 in builtin(:any)
    end

    test "is a subtype of a strategic partial" do
      assert -10..0 in (-10..-1 <|> builtin(:non_neg_integer))
      assert -1..0 in (-1 <|> builtin(:non_neg_integer))
    end

    test "is not a subtype of any of the integer classes" do
      refute -42..0 in builtin(:neg_integer)
      refute -42..0 in builtin(:pos_integer)
      refute -42..0 in builtin(:non_neg_integer)
    end
  end

  describe "a range crossing zero" do
    test "is a subtype of integer and any builtins" do
      assert -42..42 in builtin(:integer)
      assert -42..42 in builtin(:any)
    end

    test "is a subtype of strategic partials" do
      assert -10..10 in (-10..-1 <|> builtin(:non_neg_integer))
      assert -1..128 in (-1 <|> builtin(:non_neg_integer))
    end

    test "is not a subtype of any of the integer classes" do
      refute -42..42 in builtin(:neg_integer)
      refute -42..42 in builtin(:pos_integer)
      refute -42..42 in builtin(:non_neg_integer)
    end
  end

  describe "a range starting at zero" do
    test "is a subtype of integer and any builtins" do
      assert 0..42 in builtin(:non_neg_integer)
      assert 0..42 in builtin(:integer)
      assert 0..42 in builtin(:any)
    end

    test "is a subtype of correct integer classes" do
      assert 0..42 in (builtin(:non_neg_integer) <|> builtin(:atom))
      assert 0..42 in (builtin(:integer) <|> builtin(:atom))
    end

    test "is not a subtype of orthogonal types" do
      refute 0..42 in (builtin(:neg_integer) <|> builtin(:atom))
      refute 0..42 in (builtin(:pos_integer) <|> builtin(:atom))
    end

    test "is not a subtype of some integer classes" do
      refute 0..42 in builtin(:neg_integer)
      refute 0..42 in builtin(:pos_integer)
    end
  end

  describe "a positive rage" do
    test "is a subtype of integer and any builtins" do
      assert 1..47 in builtin(:pos_integer)
      assert 1..47 in builtin(:non_neg_integer)
      assert 1..47 in builtin(:integer)
      assert 1..47 in builtin(:any)
    end

    test "is a subtype of correct integer classes" do
      assert 1..47 in (builtin(:pos_integer) <|> builtin(:atom))
      assert 1..47 in (builtin(:non_neg_integer) <|> builtin(:atom))
      assert 1..47 in (builtin(:integer) <|> builtin(:atom))
    end

    test "is not a subtype of orthogonal types" do
      refute 1..47 in (builtin(:neg_integer) <|> builtin(:atom))
    end

    test "is not a subtype of some integer classes" do
      refute 1..47 in builtin(:neg_integer)
    end
  end
end
