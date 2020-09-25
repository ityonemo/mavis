defmodule TypeTest.LiteralEmptylist.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  alias Type.List

  use Type.Operators

  describe "a literal []" do
    test "is a subtype of itself" do
      assert [] in []
    end

    test "is a subtype of generic Type.List" do
      assert [] in %List{}
    end

    test "is a subtype of builtin any()" do
      assert [] in builtin(:any)
    end

    test "is a subtype of a union with itself or generic list type" do
      assert [] in ([] | builtin(:atom))
      assert [] in (%List{} | builtin(:integer))
    end

    test "is not a subtype of a union with orthogonal types" do
      refute [] in (%List{nonempty: true} | :infinity)
    end

    test "is not a subtype of nonempty lists or list with different finals" do
      refute [] in %List{nonempty: true}
      refute [] in %List{final: :foo}
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([[], %List{}])
      |> Enum.each(fn target ->
        refute [] in target
      end)
    end
  end
end
