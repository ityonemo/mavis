defmodule TypeTest.BuiltinReference.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the reference/0 type" do
    @reference_type %Type{module: nil, name: :reference, params: []}

    test "matches with itself" do
      assert reference() = @reference_type
    end
  end
end
