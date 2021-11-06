defmodule TypeTest.BuiltinNone.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the none/0 type" do
    @none_type %Type{module: nil, name: :none, params: []}

    test "matches with itself" do
      assert none() = @none_type
    end
  end
end
