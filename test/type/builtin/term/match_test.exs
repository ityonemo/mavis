defmodule TypeTest.BuiltinTerm.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the term/0 type" do
    @term_type %Type{module: nil, name: :any, params: []}

    test "matches with itself" do
      assert term() = @term_type
    end
  end
end
