defmodule TypeTest.BuiltinMfa.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the mfa/0 type" do
    @mfa_type %Type.Tuple{elements: [module(), atom(), arity()], fixed: true}

    test "matches with itself" do
      assert mfa() = @mfa_type
    end
  end
end
