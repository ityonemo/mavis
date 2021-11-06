defmodule TypeTest.BuiltinNone.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule None do
    @type none_type :: none()
  end)

  describe "the none/0 type" do
    test "is itself" do
      assert none() == @none_type
    end

    test "is what we expect" do
      assert %Type{module: nil, name: :none, params: []} == @none_type
    end
  end
end
