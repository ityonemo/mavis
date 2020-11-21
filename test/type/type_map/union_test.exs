defmodule TypeTest.TypeMap.UnionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :union

  alias Type.Map
  import Type, only: :macros

  @any any()
  @empty_map %Map{}

  describe "for the empty map type" do
    test "union with an optional or required term is the same" do
      assert map(%{optional(:foo) => @any}) == @empty_map <|> map(%{foo: @any})
      assert map(%{optional(:foo) => @any}) == @empty_map <|> map(%{optional(:foo) => @any})
      assert map(%{optional(:foo) => @any, optional(:bar) => integer()}) ==
        @empty_map <|> map(%{optional(:foo) => @any, bar: integer()})
    end
  end

  describe "for a map with a required type" do
    test "union with the same type, but optional is optional" do
      assert map(%{optional(:foo) => @any}) == map(%{foo: @any}) <|> map(%{optional(:foo) => @any})
    end

    test "unions are not merged for disjoint required types" do
      assert %Type.Union{} = map(%{foo: @any}) <|> map(%{bar: @any})
    end
  end

  describe "you can merge two maps if" do
    test "they are equal" do
      assert map(%{foo: @any}) == map(%{foo: @any}) <|> map(%{foo: @any})
    end

    test "they have the same keys with one side having bigger values" do
      assert map(%{foo: @any}) == map(%{foo: @any}) <|> map(%{foo: integer()})
    end

    test "the side that has more keys also has more values" do
      assert map(%{optional(:bar) => integer(), foo: @any}) ==
         map(%{foo: @any, bar: integer()}) <|>
         map(%{foo: integer()})
    end
  end

  describe "you can't merge two maps if" do
    test "key types are disjoint" do
      assert %Type.Union{} = map(%{foo: @any}) <|> map(%{bar: @any})
    end
    test "value sizes are inconsistent" do
      ## Why is this?  Because in this case %{foo: :baz, bar: :baz}
      ## would be in %{foo: any, bar: any} but not in either member of
      ## the union.

      assert %Type.Union{} = map(%{foo: @any, bar: integer()}) <|>
         map(%{foo: integer(), bar: @any})
    end
    test "the side that has extra keys has even one value that's smaller" do
      assert %Type.Union{} =
        map(%{foo: @any, bar: 1..10, baz: atom(), quux: integer()})<|>
        map(%{foo: @any, bar: integer(), baz: :ping})
    end
  end

end
