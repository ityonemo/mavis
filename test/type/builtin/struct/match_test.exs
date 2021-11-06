defmodule TypeTest.BuiltinStruct.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the struct/0 type" do
    @struct_type %Type.Map{
      required: %{__struct__: module()},
      optional: %{atom() => any()}}

    test "matches with itself" do
      assert struct() = @struct_type
    end
  end
end
