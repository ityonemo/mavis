defmodule TypeTest.BuiltinPort.MatchTest do
  use ExUnit.Case, async: true

  import Type, only: :macros

  @moduletag :match

  describe "the port/0 type" do
    @port_type %Type{module: nil, name: :port, params: []}

    test "matches with itself" do
      assert port() = @port_type
    end
  end
end
