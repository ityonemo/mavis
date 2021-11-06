defmodule TypeTest.BuiltinModule.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the module/0 type" do
    @module_type %Type{module: nil, name: :module, params: []}

    test "matches with itself" do
      assert module() = @module_type
    end
  end
end
