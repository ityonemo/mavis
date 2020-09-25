defmodule TypeTest.TypeList.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: [builtin: 1]

  use Type.Operators

  alias Type.List

  describe "the basic list" do
    test "is a subtype of itself and any" do
      assert %List{} in %List{}
      assert %List{} in builtin(:any)
    end

    test "if subtype if inner type is a subtype" do
      assert %List{type: 5} in %List{type: builtin(:integer)}
    end

    test "is a subtype of correct unions" do
      assert %List{type: 5} in (%List{type: builtin(:integer)} | builtin(:atom))
    end

    test "is not a subtype of unions of orthogonal types" do
      refute %List{type: builtin(:integer)} in (%List{type: builtin(:atom)} | builtin(:atom))
    end

    test "is not a subtype if the inner type is not a subtype" do
      refute %List{type: builtin(:atom)} in %List{type: builtin(:integer)}
    end

    test "is not a subtype if the inner type is the same but nonempty" do
      refute %List{type: builtin(:atom)} in %List{type: builtin(:atom), nonempty: true}
    end

    test "is not a subtype if the inner type is the same but with a different final" do
      refute %List{type: builtin(:atom)} in %List{type: builtin(:atom), final: builtin(:integer)}
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([%List{}])
      |> Enum.each(fn target ->
        refute %List{} in target
      end)
    end
  end

  describe "the a nonempty list" do
    test "is a subtype of itself and any" do
      assert %List{nonempty: true} in %List{nonempty: true}
      assert %List{nonempty: true} in builtin(:any)
    end

    test "is a subtype of nonempty false self" do
      assert %List{nonempty: true} in %List{}
      assert %List{type: builtin(:integer), nonempty: true} in %List{type: builtin(:integer)}
    end

    test "if subtype if inner type is a subtype" do
      assert %List{type: 5, nonempty: true} in %List{type: builtin(:integer), nonempty: true}
    end

    test "is not a subtype if the inner type is not a subtype" do
      refute %List{type: builtin(:atom), nonempty: true} in %List{type: builtin(:integer), nonempty: true}
    end
  end

  describe "a list with final defined" do
    test "is a subtype of itself and any" do
      assert %List{final: builtin(:integer)} in %List{final: builtin(:integer)}
      assert %List{final: builtin(:integer)} in builtin(:any)
    end

    test "if subtype if final is a subtype" do
      assert %List{final: 47} in %List{final: builtin(:integer)}
    end

    test "is not a subtype if final is not a subtype" do
      refute %List{final: builtin(:integer)} in %List{final: 47}
    end
  end
end
