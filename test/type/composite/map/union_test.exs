defmodule TypeTest.TypeMap.UnionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :union
  @moduletag :map

  alias Type.Map
  import Type, only: :macros

  @empty_map %Map{}

  describe "for the empty map type" do
    test "union with an optional or required term is the same" do
      assert type(%{optional(:foo) => any()}) == @empty_map <|> type(%{foo: any()})
      assert type(%{optional(:foo) => any()}) == @empty_map <|> type(%{optional(:foo) => any()})
      assert type(%{optional(:foo) => any(), optional(:bar) => integer()}) ==
        @empty_map <|> type(%{optional(:foo) => any(), bar: integer()})
    end
  end

  describe "for a map with a required type" do
    test "union with the same type, but optional is optional" do
      assert type(%{optional(:foo) => any()}) == type(%{foo: any()}) <|> type(%{optional(:foo) => any()})
    end

    test "unions are not merged for disjoint required types" do
      assert %Type.Union{} = type(%{foo: any()}) <|> type(%{bar: any()})
    end
  end

  describe "you can merge two maps if" do
    test "they are equal" do
      assert type(%{foo: any()}) == type(%{foo: any()}) <|> type(%{foo: any()})
    end

    test "they have the same keys with one side having bigger values" do
      assert type(%{foo: any()}) == type(%{foo: any()}) <|> type(%{foo: integer()})
    end

    test "the side that has more keys also has more values" do
      assert type(%{optional(:bar) => integer(), foo: any()}) ==
         type(%{foo: any(), bar: integer()}) <|>
         type(%{foo: integer()})
    end
  end

  describe "you can't merge two maps if" do
    test "key types are disjoint" do
      assert %Type.Union{} = type(%{foo: any()}) <|> type(%{bar: any()})
    end
    test "value sizes are inconsistent" do
      ## Why is this?  Because in this case %{foo: :baz, bar: :baz}
      ## would be in %{foo: any, bar: any} but not in either member of
      ## the union.

      assert %Type.Union{} = type(%{foo: any(), bar: integer()}) <|>
         type(%{foo: integer(), bar: any()})
    end
    test "the side that has extra keys has even one value that's smaller" do
      assert %Type.Union{} =
        type(%{foo: any(), bar: 1..10, baz: atom(), quux: integer()})<|>
        type(%{foo: any(), bar: integer(), baz: :ping})
    end
  end

end
