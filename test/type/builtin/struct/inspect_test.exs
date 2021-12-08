defmodule TypeTest.BuiltinStruct.InspectTest do
  use ExUnit.Case, async: true

  import TypeTest.FetchCase
  import TypeTest.InspectCase

  @moduletag :inspect
  @moduletag :struct

  describe "the struct type" do
    pull_types(defmodule Struct do
      @type struct_type :: struct()
    end)

    test "is presented as itself" do
      assert "struct()" == inspect(@struct_type)
    end

    test "code translates correctly" do
      assert @struct_type == eval_inspect(@struct_type)
    end

    test "with module is presented as struct" do
      import Type, only: :macros
      assert "struct()" == inspect(
        %Type.Map{
          required: %{__struct__: module()},
          optional: %{atom() => any()}})
    end
  end
end
