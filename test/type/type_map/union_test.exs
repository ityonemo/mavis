defmodule TypeTest.TypeMap.UnionTest do
  use ExUnit.Case, async: true
  use Type.Operators

  @moduletag :union

  alias Type.Map
  import Type, only: [builtin: 1]

  @any builtin(:any)
  @empty_map %Map{}

  describe "for the empty map type" do
    test "either a required or optional descriptor works" do
      assert Map.build(%{foo: @any}, %{}) ==
        (@empty_map | Map.build(%{foo: @any}, %{}))
      assert Map.build(foo: @any) ==
        (@empty_map | Map.build(foo: @any))
    end
  end

end
