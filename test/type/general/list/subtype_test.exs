defmodule TypeTest.TypeList.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.List

  describe "the basic list" do
    test "is a subtype of itself and any" do
      assert list() in list()
      assert list() in any()
    end

    test "if subtype if inner type is a subtype" do
      assert list(47) in list(integer())
    end

    test "is a subtype of correct unions" do
      assert list(47) in (list(integer()) <|> atom())
    end

    test "is not a subtype of unions of orthogonal types" do
      refute list(integer()) in (list(atom()) <|> atom())
    end

    test "is not a subtype if the inner type is not a subtype" do
      refute list(atom()) in list(integer())
    end

    test "is not a subtype if the inner type is the same but nonempty" do
      refute list(atom()) in list(atom(), ...)
    end

    test "is not a subtype if the inner type is the same but with a different final" do
      refute list(atom()) in %List{type: atom(), final: integer()}
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([list()])
      |> Enum.each(fn target ->
        refute list() in target
      end)
    end
  end

  describe "the a nonempty list" do
    test "is a subtype of itself and any" do
      assert list(...) in list(...)
      assert list(...) in any()
    end

    test "is a subtype of nonempty false self" do
      assert list(...) in list()
      assert list(integer(), ...) in list(integer())
    end

    test "if subtype if inner type is a subtype" do
      assert list(47, ...) in list(integer(), ...)
    end

    test "is not a subtype if the inner type is not a subtype" do
      refute list(atom(), ...) in list(integer(), ...)
    end
  end

  describe "a list with final defined" do
    test "is a subtype of itself and any" do
      assert %List{final: integer()} in %List{final: integer()}
      assert %List{final: integer()} in any()
    end

    test "if subtype if final is a subtype" do
      assert %List{final: 47} in %List{final: integer()}
    end

    test "is not a subtype if final is not a subtype" do
      refute %List{final: integer()} in %List{final: 47}
    end
  end
end
