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
      assert %Map{required: [foo: @any]} == (@empty_map | %Map{required: [foo: @any]})
      assert %Map{optional: [foo: @any]} == (@empty_map | %Map{optional: [foo: @any]})
    end
  end

end
