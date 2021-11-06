defmodule TypeTest.BuiltinMfa.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Mfa do
    @type mfa_type :: mfa()
  end)

  describe "the mfa/0 type" do
    test "is itself" do
      assert mfa() == @mfa_type
    end

    test "is what we expect" do
      assert %Type.Tuple{elements: [module(), atom(), arity()], fixed: true} == @mfa_type
    end
  end
end
