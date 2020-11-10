defmodule TypeTest.LiteralEmptyList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.List

  describe "the intersection of a literal empty list" do
    test "with itself, general lists and any is itself" do
      assert [] == [] <~> builtin(:any)
      assert [] == [] <~> list(:foo)
      assert [] == [] <~> builtin(:list)
      assert [] == [] <~> []
    end

    test "with nonempty, or odd-termination final lists is not ok" do
      assert builtin(:none) == [] <~> %List{final: :foo}
      assert builtin(:none) == [] <~> list(...)
    end

    test "with unions works as expected" do
      assert [] == [] <~> ([] <|> builtin(:integer))
      assert builtin(:none) == [] <~> (builtin(:integer) <|> builtin(:port))
    end

    test "with all other types is none" do
      TypeTest.Targets.except([[], builtin(:list)])
      |> Enum.each(fn target ->
        assert builtin(:none) == [] <~> target
      end)
    end
  end
end
