defmodule TypeTest.BuiltinIdentifier.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  describe "the identifier type" do
    pull_types(defmodule Identifier do
      @type identifier_type :: identifier
    end)

    test "is itself" do
      assert identifier() == @identifier_type
    end

    test "matches to itself" do
      assert identifier() = @identifier_type
    end

    test "is what we expect" do
      assert %Type.Union{of: [
        %Type{module: nil, name: :pid, params: []},
        %Type{module: nil, name: :port, params: []},
        %Type{module: nil, name: :reference, params: []},
      ]} == @identifier_type
    end
  end
end
