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

    test "is not a subtype if the inner type is a subtype" do
      refute %List{type: builtin(:atom)} in %List{type: builtin(:integer)}
    end
  end
end
