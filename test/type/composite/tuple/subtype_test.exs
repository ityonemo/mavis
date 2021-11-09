defmodule TypeTest.TypeTuple.SubtypeTest do
  use ExUnit.Case, async: true

  @moduletag :subtype

  import Type, only: :macros

  use Type.Operators

  @any_tuple tuple()
  @min_2_tuple type({any(), any(), ...})

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
      TypeTest.Targets.except([type({})])
      |> Enum.each(fn target ->
        refute @any_tuple in target
      end)
    end
  end

  describe "defined tuples" do
    test "are subtypes of any tuple and any" do
      assert type({}) in @any_tuple
      assert type({integer()}) in @any_tuple
      assert type({atom(), integer()}) in @any_tuple

      assert type({}) in any()
      assert type({integer()}) in any()
      assert type({atom(), integer()}) in any()
    end

    test "are subtypes of qualified minimum tuples" do
      assert type({:ok, integer()}) in @min_2_tuple
    end

    test "are subtypes of themselves" do
      assert type({}) in type({})

      assert type({integer()}) in
        type({integer()})
      assert type({atom(), integer()}) in
        type({atom(), integer()})
    end

    test "are subtypes of unions with themselves, supertuples, or any tuple" do
      assert type({integer()}) in (type({integer()}) <|> integer())
      assert type({integer()}) in (type({any()}) <|> integer())
      assert type({integer()}) in (@any_tuple <|> integer())
    end

    test "are subtypes when their elements are subtypes" do
      assert type({47}) in type({integer()})
      assert type({47, :foo}) in type({integer(), atom()})
    end

    test "are not subtypes of orthogonal unions" do
      refute type({integer()}) in
        (type({integer(), integer()}) <|> integer())
    end

    test "are not subtypes when their length is insufficient" do
      refute type({integer()}) in @min_2_tuple
    end

    test "is not a subtype on partial match" do
      refute type({47, :foo}) in type({atom(), atom()})
      refute type({47, :foo}) in type({integer(), integer()})
    end

    test "is not a subtype if the lengths don't agree" do
      refute type({integer()}) in type({integer(), integer()})
    end

    test "are not subtypes of other types" do
      TypeTest.Targets.except([type({})])
      |> Enum.each(fn target ->
        refute type({}) in target
        refute type({integer()}) in target
        refute type({atom(), integer()}) in target
      end)
    end
  end
end
