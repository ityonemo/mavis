defmodule TypeTest.TypeList.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.List

  describe "the basic list" do
    test "is a subtype of itself and any" do
      assert builtin(:list) in builtin(:list)
      assert builtin(:list) in builtin(:any)
    end

    test "if subtype if inner type is a subtype" do
      assert list(47) in list(builtin(:integer))
    end

    test "is a subtype of correct unions" do
      assert list(47) in (list(builtin(:integer)) <|> builtin(:atom))
    end

    test "is not a subtype of unions of orthogonal types" do
      refute list(builtin(:integer)) in (list(builtin(:atom)) <|> builtin(:atom))
    end

    test "is not a subtype if the inner type is not a subtype" do
      refute list(builtin(:atom)) in list(builtin(:integer))
    end

    test "is not a subtype if the inner type is the same but nonempty" do
      refute list(builtin(:atom)) in list(builtin(:atom), ...)
    end

    test "is not a subtype if the inner type is the same but with a different final" do
      refute list(builtin(:atom)) in %List{type: builtin(:atom), final: builtin(:integer)}
    end

    test "is not a subtype of other types" do
      TypeTest.Targets.except([builtin(:list)])
      |> Enum.each(fn target ->
        refute builtin(:list) in target
      end)
    end
  end

  describe "the a nonempty list" do
    test "is a subtype of itself and any" do
      assert list(...) in list(...)
      assert list(...) in builtin(:any)
    end

    test "is a subtype of nonempty false self" do
      assert list(...) in builtin(:list)
      assert list(builtin(:integer), ...) in list(builtin(:integer))
    end

    test "if subtype if inner type is a subtype" do
      assert list(47, ...) in list(builtin(:integer), ...)
    end

    test "is not a subtype if the inner type is not a subtype" do
      refute list(builtin(:atom), ...) in list(builtin(:integer), ...)
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
