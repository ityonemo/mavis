defmodule TypeTest.TypeList.IntersectionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :intersection

  import Type, only: :macros

  alias Type.List

  describe "normal list" do
    test "intersects with any and self" do
      assert builtin(:list) == builtin(:list) <~> builtin(:any)
      assert builtin(:list) == builtin(:list) <~> builtin(:list)
    end

    test "intersects with empty list as empty list" do
      assert [] == builtin(:list) <~> []
    end

    test "intersects with another list with the intersection of types" do
      assert list(builtin(:integer)) == builtin(:list) <~> list(builtin(:integer))
      assert list(47) == list(47) <~> list(builtin(:integer))
    end

    test "with unions works as expected" do
      assert [] == builtin(:list) <~> ([] <|> builtin(:atom))
      assert builtin(:none) == builtin(:list) <~> (builtin(:atom) <|> builtin(:port))
    end

    test "doesn't intersect with anything else" do
      TypeTest.Targets.except([builtin(:list), []])
      |> Enum.each(fn target ->
        assert builtin(:none) == builtin(:list) <~> target
      end)
    end
  end

  describe "nonempty list" do
    test "intersects with any and self" do
      assert list(...) == builtin(:list) <~> list(...)
      assert list(...) == list(...) <~> builtin(:list)
    end

    test "doesn't intersect with empty list" do
      assert builtin(:none) == [] <~> list(...)
      assert builtin(:none) == list(...) <~> []
    end
  end

  describe "list finals" do
    test "are reduced" do
      assert %List{final: builtin(:pos_integer)} ==
        %List{final: builtin(:pos_integer)} <~> %List{final: builtin(:integer)}
      assert %List{final: builtin(:pos_integer)} ==
        %List{final: builtin(:integer)} <~> %List{final: builtin(:pos_integer)}
    end
  end
end
