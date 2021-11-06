defmodule TypeTest.BuiltinIdentifier.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Identifier do
    @type identifier_type :: identifier
  end)

  describe "the identifier/0 type" do
    test "is itself" do
      assert identifier() == @identifier_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [pid(), port(), reference()]} == @identifier_type
    end
  end
end
