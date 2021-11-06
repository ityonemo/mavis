defmodule TypeTest.BuiltinModule.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Module do
    @type module_type :: module()
  end)

  describe "the module type" do
    test "is itself" do
      assert module() == @module_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :module, params: []} == @module_type
    end
  end
end
