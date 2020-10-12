defmodule TypeTest.LiteralInteger.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: [builtin: 1]

  describe "the intersection of a literal integer" do
    test "with itself, integer and any is itself" do
      assert 47 == 47 <~> builtin(:any)
      assert 47 == 47 <~> builtin(:integer)
      assert 47 == 47 <~> 47
    end

    test "with integer types is correct" do
      assert -47 == -47 <~> builtin(:neg_integer)
      assert builtin(:none) == -47 <~> builtin(:pos_integer)
      assert builtin(:none) == -47 <~> builtin(:non_neg_integer)

      assert builtin(:none) == 0 <~> builtin(:neg_integer)
      assert builtin(:none) == 0 <~> builtin(:pos_integer)
      assert 0 == 0 <~> builtin(:non_neg_integer)

      assert builtin(:none) == 47 <~> builtin(:neg_integer)
      assert 47 == 47 <~> builtin(:pos_integer)
      assert 47 == 47 <~> builtin(:non_neg_integer)
    end

    test "with ranges is correct" do
      assert 47 == 47 <~> 0..50
      assert builtin(:none) == 42 <~> 0..10
    end

    test "with unions works as expected" do
      assert 47 == 47 <~> (builtin(:integer) <|> :infinity)
      assert builtin(:none) == 47 <~> (builtin(:atom) <|> builtin(:port))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([builtin(:integer), builtin(:pos_integer), builtin(:non_neg_integer)])
      |> Enum.each(fn target ->
        assert builtin(:none) == 42 <~> target
      end)
    end
  end
end
