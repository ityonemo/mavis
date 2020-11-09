defmodule TypeTest.TypeTuple.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.Tuple

  @anytuple builtin(:tuple)

  describe "any tuple" do
    test "intersects with any and self" do
      assert @anytuple == @anytuple <~> builtin(:any)
      assert @anytuple == @anytuple <~> @anytuple
    end

    test "turns into its counterparty" do
      assert tuple({}) == @anytuple <~> tuple({})
      assert tuple({:foo}) == @anytuple <~> tuple({:foo})
      assert tuple({:foo, builtin(:integer)}) ==
        @anytuple <~> tuple({:foo, builtin(:integer)})
    end

    test "with unions works as expected" do
      assert tuple({}) == @anytuple <~> (tuple({}) <|> 1..10)
      assert builtin(:none) == @anytuple <~> (builtin(:atom) <|> builtin(:port))
    end

    test "doesn't intersect with anything else" do
      TypeTest.Targets.except([@anytuple, tuple({})])
      |> Enum.each(fn target ->
        assert builtin(:none) == @anytuple <~> target
      end)
    end
  end

  describe "tuples with defined elements" do
    test "intersect with the cartesian intersection" do
      assert tuple({:foo}) == tuple({:foo}) <~> tuple({builtin(:atom)})
      assert tuple({:foo}) == tuple({builtin(:atom)}) <~> tuple({:foo})

      assert tuple({:foo, 47}) ==
        tuple({:foo, builtin(:integer)}) <~>
        tuple({builtin(:atom), 47})
      assert tuple({:foo, 47}) ==
        tuple({builtin(:atom), builtin(:integer)}) <~>
        tuple({:foo, 47})
      assert tuple({:foo, 47}) ==
        tuple({:foo, 47}) <~>
        tuple({builtin(:atom), builtin(:integer)})
    end

    test "a single mismatch yields none" do
      assert builtin(:none) == tuple({:foo}) <~> tuple({:bar})
      assert builtin(:none) == tuple({:foo, :bar}) <~> tuple({:bar, :bar})
      assert builtin(:none) == tuple({:bar, :bar}) <~> tuple({:bar, :foo})
    end
  end
end
