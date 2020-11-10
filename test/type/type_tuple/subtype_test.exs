defmodule TypeTest.TypeTuple.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  @any_tuple builtin(:tuple)

  describe "any tuples" do
    test "are subtypes of themselves and any" do
      assert @any_tuple in builtin(:any)
    end

    test "are subtypes of tuples containing any tuples" do
      assert @any_tuple in (builtin(:atom) <|> @any_tuple)
    end

    test "are not subtypes of orthogonal unions" do
      refute @any_tuple in (builtin(:atom) <|> builtin(:integer))
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([tuple({})])
      |> Enum.each(fn target ->
        refute @any_tuple in target
      end)
    end
  end

  describe "defined tuples" do
    test "are subtypes of any tuple and any" do
      assert tuple({}) in @any_tuple
      assert tuple({builtin(:integer)}) in @any_tuple
      assert tuple({builtin(:atom), builtin(:integer)}) in @any_tuple

      assert tuple({}) in builtin(:any)
      assert tuple({builtin(:integer)}) in builtin(:any)
      assert tuple({builtin(:atom), builtin(:integer)}) in builtin(:any)
    end

    test "are subtypes of themselves" do
      assert tuple({}) in tuple({})

      assert tuple({builtin(:integer)}) in
        tuple({builtin(:integer)})
      assert tuple({builtin(:atom), builtin(:integer)}) in
        tuple({builtin(:atom), builtin(:integer)})
    end

    test "are subtypes of unions with themselves, supertuples, or any tuple" do
      assert tuple({builtin(:integer)}) in (tuple({builtin(:integer)}) <|> builtin(:integer))
      assert tuple({builtin(:integer)}) in (tuple({builtin(:any)}) <|> builtin(:integer))
      assert tuple({builtin(:integer)}) in (@any_tuple <|> builtin(:integer))
    end

    test "are subtypes when their elements are subtypes" do
      assert tuple({47}) in tuple({builtin(:integer)})
      assert tuple({47, :foo}) in tuple({builtin(:integer), builtin(:atom)})
    end

    test "are not subtypes of orthogonal unions" do
      refute tuple({builtin(:integer)}) in
        (tuple({builtin(:integer), builtin(:integer)}) <|> builtin(:integer))
    end

    test "is not a subtype on partial match" do
      refute tuple({47, :foo}) in tuple({builtin(:atom), builtin(:atom)})
      refute tuple({47, :foo}) in tuple({builtin(:integer), builtin(:integer)})
    end

    test "is not a subtype if the lengths don't agree" do
      refute tuple({builtin(:integer)}) in tuple({builtin(:integer), builtin(:integer)})
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([tuple({})])
      |> Enum.each(fn target ->
        refute tuple({}) in target
        refute tuple({builtin(:integer)}) in target
        refute tuple({builtin(:atom), builtin(:integer)}) in target
      end)
    end
  end
end
