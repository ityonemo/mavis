defmodule TypeTest.TypeFunction.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  alias Type.Function

  @any_function function()

  describe "the any() function" do
    test "is a subtype of itself and any()" do
      assert @any_function in @any_function
      assert @any_function in any()
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([])
      |> Enum.each(fn target ->
        refute @any_function in target
      end)
    end
  end

  describe "for a defined return function" do
    test "is a subtype when the return is a subtype" do
      assert type((... -> :foo)) in type((... -> atom()))
    end

    test "is not a subtype when the return is not a subtype" do
      refute type((... -> :foo)) in type((... -> integer()))
    end
  end

  describe "when the parameters are defined" do
    test "they are subtypes when the parameters match and the return matches" do
      assert type((integer() -> integer())) in type((integer() -> any()))
    end

    test "they are not subtypes when the returns don't match" do
      refute type((integer() -> any())) in type((integer() -> integer()))
    end

    test "they are not subtypes when the params are not equal" do
      refute type((integer() -> any())) in type((pos_integer() -> any()))

      refute type((pos_integer() -> any())) in type((integer() -> any()))
    end

    test "they are not subtypes when the param lengths are not equal" do
      refute type((integer() -> any())) in type((integer(), integer() -> any()))
    end
  end
end
