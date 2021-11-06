defmodule TypeTest.BuiltinStruct.FetchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros
  import TypeTest.FetchCase

  @moduletag :fetch

  pull_types(defmodule Struct do
    @type struct_type :: struct()
  end)

  describe "the struct/0 type" do
    test "is itself" do
      assert struct() == @struct_type
    end

    test "is what we expect" do
      assert %Type.Map{optional: %{atom() => any()}, required: %{__struct__: module()}} == @struct_type
    end
  end
end
