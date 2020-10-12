defmodule TypeTest.TypeMap.UnionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :union

  alias Type.Map
  import Type, only: [builtin: 1]

  @any builtin(:any)
  @empty_map %Map{}

  describe "for the empty map type" do
    test "union with an optional or required term is the same" do
      assert Map.build(foo: @any) ==
        (@empty_map <|> Map.build(%{foo: @any}, %{}))
      assert Map.build(foo: @any) ==
        (@empty_map <|> Map.build(foo: @any))
      assert Map.build(%{foo: @any, bar: builtin(:integer)}) ==
        (@empty_map <|> Map.build(%{foo: @any}, %{bar: builtin(:integer)}))
    end
  end

  describe "for a map with a required type" do
    test "union with the same type, but optional is optional" do
      assert Map.build(foo: @any) ==
        (Map.build(foo: @any) <|> Map.build(foo: @any))
    end

    test "unions are not merged for disjoint required types" do
      assert %Type.Union{} =
        (Map.build(foo: @any) <|> Map.build(bar: @any))
    end
  end

  describe "you can merge two maps if" do
    test "they are equal" do
      assert Map.build(foo: @any) ==
        (Map.build(foo: @any) <|> Map.build(foo: @any))
    end
    test "they have the same keys with one side having bigger values" do
      assert Map.build(foo: @any) ==
        (Map.build(foo: @any) <|> Map.build(foo: builtin(:integer)))
    end
    test "the side that has more keys also has more values" do
      assert Map.build(foo: @any, bar: builtin(:integer)) ==
        (Map.build(foo: @any, bar: builtin(:integer)) <|>
         Map.build(foo: builtin(:integer)))
    end
  end

  describe "you can't merge two maps if" do
    test "key types are disjoint" do
      assert %Type.Union{} =
        (Map.build(foo: @any) <|> Map.build(bar: @any))
    end
    test "value sizes are inconsistent" do
      ## Why is this?  Because in this case %{foo: :baz, bar: :baz}
      ## would be in %{foo: any, bar: any} but not in either member of
      ## the union.

      assert %Type.Union{} =
        (Map.build(foo: @any, bar: builtin(:integer)) <|>
         Map.build(foo: builtin(:integer), bar: @any))
    end
    test "the side that has extra keys has even one value that's smaller" do
      assert %Type.Union{} =
        (Map.build(foo: @any, bar: 1..10, baz: builtin(:atom), quux: builtin(:integer)) <|>
         Map.build(foo: @any, bar: builtin(:integer), baz: :ping))
    end
  end

end
