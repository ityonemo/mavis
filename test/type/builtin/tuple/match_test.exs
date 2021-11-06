defmodule TypeTest.BuiltinTerm.TupleTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the tuple/0 type" do
    @tuple_type %Type.Tuple{elements: [], fixed: false}

    test "matches with itself" do
      assert tuple() = @tuple_type
    end
  end
end
