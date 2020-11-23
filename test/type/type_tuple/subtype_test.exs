defmodule TypeTest.TypeTuple.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  @any_tuple tuple()
  @min_2_tuple tuple({any(), any(), ...})

  describe "minimum tuples" do
    test "are subtypes of themselves and any" do
      assert @any_tuple in any()
      assert @any_tuple in @any_tuple
      assert @min_2_tuple in @any_tuple
      assert @min_2_tuple in @min_2_tuple
    end

    test "are subtypes of tuples containing any tuples" do
      assert @any_tuple in (atom() <|> @any_tuple)
      assert @min_2_tuple in (atom() <|> @min_2_tuple)
    end

    test "are not subtypes of orthogonal unions" do
      refute @any_tuple in (atom() <|> integer())
      refute @min_2_tuple in (atom() <|> integer())
    end

    test "are not subtypes of more stringent minimum tuples" do
      refute @any_tuple in @min_2_tuple
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
      assert tuple({integer()}) in @any_tuple
      assert tuple({atom(), integer()}) in @any_tuple

      assert tuple({}) in any()
      assert tuple({integer()}) in any()
      assert tuple({atom(), integer()}) in any()
    end

    test "are subtypes of qualified minimum tuples" do
      assert tuple({:ok, integer()}) in @min_2_tuple
    end

    test "are subtypes of themselves" do
      assert tuple({}) in tuple({})

      assert tuple({integer()}) in
        tuple({integer()})
      assert tuple({atom(), integer()}) in
        tuple({atom(), integer()})
    end

    test "are subtypes of unions with themselves, supertuples, or any tuple" do
      assert tuple({integer()}) in (tuple({integer()}) <|> integer())
      assert tuple({integer()}) in (tuple({any()}) <|> integer())
      assert tuple({integer()}) in (@any_tuple <|> integer())
    end

    test "are subtypes when their elements are subtypes" do
      assert tuple({47}) in tuple({integer()})
      assert tuple({47, :foo}) in tuple({integer(), atom()})
    end

    test "are not subtypes of orthogonal unions" do
      refute tuple({integer()}) in
        (tuple({integer(), integer()}) <|> integer())
    end

    test "are not subtypes when their length is insufficient" do
      refute tuple({integer()}) in @min_2_tuple
    end

    test "is not a subtype on partial match" do
      refute tuple({47, :foo}) in tuple({atom(), atom()})
      refute tuple({47, :foo}) in tuple({integer(), integer()})
    end

    test "is not a subtype if the lengths don't agree" do
      refute tuple({integer()}) in tuple({integer(), integer()})
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([tuple({})])
      |> Enum.each(fn target ->
        refute tuple({}) in target
        refute tuple({integer()}) in target
        refute tuple({atom(), integer()}) in target
      end)
    end
  end
end
